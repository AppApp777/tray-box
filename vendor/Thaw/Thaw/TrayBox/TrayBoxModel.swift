import AppKit
import Observation

/// One user operation at a time. Closing is gated by both drag and move lifetime.
@MainActor @Observable
final class TrayBoxModel {
    var editing = false
    var busy = false
    var dragging = false
    var restoringMenu = false
    var message = "点击图标打开菜单，点整理调整位置"
    var hasError = false
    var keepsPanelOpen: Bool { busy || dragging || restoringMenu }
    private weak var appState: AppState?
    private(set) var displayID: CGDirectDisplayID = 0

    func configure(appState: AppState, screen: NSScreen) {
        self.appState = appState
        self.displayID = screen.displayID
    }
    func items(in section: MenuBarSection.Name) -> [MenuBarItem] {
        guard let appState else { return [] }
        let sections: [MenuBarSection.Name] = section == .hidden ? [.hidden, .alwaysHidden] : [.visible]
        return sections.flatMap { appState.itemManager.itemCache.managedItems(for: $0) }
            .filter { !$0.isControlItem && !$0.isSystemClone && TrayBoxConfiguration.accepts($0) }
    }
    func image(for item: MenuBarItem) -> NSImage? { appState?.imageCache.images[item.tag]?.nsImage ?? item.sourceApplication?.icon }
    func name(for item: MenuBarItem) -> String {
        if let title = item.title, title.hasPrefix("thaw.baseline.fixture.") {
            return "测试 " + String(title.suffix(1))
        }
        return item.displayName
    }
    func refresh() async {
        guard let appState, !busy, !dragging else { return }
        await appState.itemManager.cacheItemsRegardless(skipRecentMoveCheck: true, skipSavedLayoutApply: true)
        await appState.imageCache.updateCacheWithoutChecks(sections: [.visible, .hidden, .alwaysHidden])
    }
    private func fresh(_ item: MenuBarItem, from items: [MenuBarItem]) -> MenuBarItem? {
        let matches = items.filter {
            Self.matchesSnapshot($0, selected: item)
        }
        guard matches.count == 1, let result = matches.first,
              TrayBoxConfiguration.accepts(result) else { return nil }
        return result
    }
    static func matchesSnapshot(_ current: MenuBarItem, selected: MenuBarItem) -> Bool {
        let sameSource = current.sourcePID == selected.sourcePID
            && current.tag.namespace == selected.tag.namespace
        guard sameSource else { return false }
        return (current.windowID == selected.windowID && current.title == selected.title)
            || current.tag == selected.tag
    }
    private func fail(_ text: String) { hasError = true; message = text }

    func move(_ selected: MenuBarItem, to section: MenuBarSection.Name) async {
        guard !busy, let appState, TrayBoxConfiguration.accepts(selected) else { return }
        busy = true; hasError = false; message = "正在移动\(name(for: selected))…"
        let manager = appState.itemManager
        var revealed: ControlItem?
        defer {
            // desiredState is untouched; even errors/cancellation restore the spacer.
            revealed.map { _ in appState.menuBarManager.section(withName: .hidden)?.updateControlItemState(for: nil) }
            busy = false
        }
        do {
            var live = await MenuBarItem.getMenuBarItems(option: .activeSpace)
            guard let source = fresh(selected, from: live), source.isMovableAddressingWindowOwner else {
                fail("这个图标已变化，刷新后再试"); return
            }
            let destination: MenuBarItemManager.MoveDestination
            if section == .visible {
                guard let anchor = live.first(matching: .visibleControlItem) else {
                    fail("暂时没有找到收纳按钮，请稍后再试"); return
                }
                destination = .rightOfItem(anchor)
            } else {
                // Prefer a real hidden neighbor. An empty section needs its
                // divider briefly exposed, as in upstream's layout editor.
                let candidates = items(in: .hidden).filter { $0.windowID != source.windowID }
                if let neighbor = candidates.last.flatMap({ fresh($0, from: live) }) {
                    destination = .rightOfItem(neighbor)
                } else {
                    guard let control = appState.menuBarManager.controlItem(withName: .hidden) else {
                        fail("暂时没有找到收纳边界"); return
                    }
                    revealed = control
                    control.state = .showSection
                    try await Task.sleep(for: .milliseconds(200))
                    live = await MenuBarItem.getMenuBarItems(option: .activeSpace)
                    guard let divider = live.first(matching: .hiddenControlItem),
                          NSScreen.screens.contains(where: { CGDisplayBounds($0.displayID).intersects(divider.liveBounds) }) else {
                        fail("收纳边界还没就绪，请稍后再试"); return
                    }
                    destination = .leftOfItem(divider)
                }
            }
            var moveError: (any Error)?
            do {
                try await manager.move(item: source, to: destination, on: displayID,
                                       skipInputPause: true, watchdogTimeout: .seconds(5), maxMoveAttempts: 3)
            } catch { moveError = error }
            if revealed != nil {
                appState.menuBarManager.section(withName: .hidden)?.updateControlItemState(for: nil)
                revealed = nil
            }
            try await Task.sleep(for: .milliseconds(250))
            let after = await MenuBarItem.getMenuBarItems(option: .activeSpace)
            guard let actual = fresh(source, from: after),
                  let divider = after.first(matching: .hiddenControlItem),
                  Self.isInSection(actual.liveBounds, divider: divider.liveBounds, section: section) else {
                fail("这次未能确认移动结果，已重新收起顶栏并刷新")
                appState.diagLog.error("TrayBox move not verified: \(String(describing: moveError))")
                await manager.cacheItemsRegardless(skipRecentMoveCheck: true, skipSavedLayoutApply: true)
                return
            }
            manager.recordExternalMoveOperation()
            manager.removeTemporarilyShownItemFromCache(with: source.tag)
            await manager.cacheItemsRegardless(skipRecentMoveCheck: true, skipSavedLayoutApply: true)
            Task { await appState.imageCache.updateCacheWithoutChecks(sections: [.hidden, .visible]) }
            message = "\(name(for: actual))已" + (section == .visible ? "放回顶栏" : "收进来")
        } catch {
            fail("移动已中止，顶栏已重新收起")
        }
    }
    static func isInSection(_ bounds: CGRect, divider: CGRect, section: MenuBarSection.Name) -> Bool {
        guard bounds.width > 0, divider.width > 0, bounds.minX != -1,
              abs(bounds.midY - divider.midY) < max(bounds.height, divider.height) else { return false }
        return section == .visible ? bounds.minX >= divider.maxX - 1 : bounds.maxX <= divider.minX + 1
    }

    func openMenu(_ selected: MenuBarItem, right: Bool = false) async {
        guard !busy, let appState, TrayBoxConfiguration.accepts(selected) else { return }
        busy = true; hasError = false
        // Explicit opening is allowed to dismiss; outside clicks during moves aren't.
        appState.menuBarManager.iceBarPanel.dismissForMenu()
        defer { busy = false }
        await appState.menuBarManager.iceBarPanel.waitUntilClosed(timeout: .milliseconds(200))
        let live = await MenuBarItem.getMenuBarItems(option: .activeSpace)
        guard let item = fresh(selected, from: live) else {
            fail("图标已变化，请重新打开收纳盒"); return
        }
        let onScreen = CGDisplayBounds(displayID).contains(item.liveBounds)
        if onScreen {
            do { try await appState.itemManager.click(item: item, with: right ? .right : .left) }
            catch { fail("暂时没能打开这个菜单") }
        } else {
            let result = await appState.itemManager.temporarilyShow(item: item,
                clickingWith: right ? .right : .left, on: displayID, fastPath: true)
            if case .movedAndClicked = result {} else { fail("暂时没能打开这个菜单") }
        }
        if hasError, let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) {
            appState.menuBarManager.iceBarPanel.show(section: .hidden, on: screen)
        }
    }
}
