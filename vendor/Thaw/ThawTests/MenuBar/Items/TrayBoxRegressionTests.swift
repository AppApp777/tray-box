import AppKit
import Testing
@testable import Thaw

@Suite("TrayBox integration", .serialized)
@MainActor struct TrayBoxRegressionTests {
    @Test("Manual mode returns false for a disappearing window, allowing a fresh cache publication")
    func manualModeDoesNotClaimADeferredApply() async throws {
        try await withScratchDefaults { _ in
            Defaults.set(false, forKey: .automaticArrangementEnabled)
            let manager = MenuBarItemManager()
            manager.suppressNextNewLeftmostItemRelocation = false
            let item = MenuBarItem.fixture(tag: .appItem(bundleID: "local.miao.test", title: "A"),
                windowID: 1_999_001, bounds: CGRect(x: 620, y: 0, width: 24, height: 24), sourcePID: 999_999)
            manager.savedSectionOrder = ["visible": [item.uniqueIdentifier]]
            let applied = await manager.applySavedLayout(items: [item],
                previousCycle: .init(windowIDs: [1_999_001, 1_999_002], displayID: nil),
                controlItems: .fixture(hiddenAt: CGRect(x: 590, y: 0, width: 20, height: 24)))
            #expect(!applied)
            // This is the caller's contract: only a real layout apply owns the
            // subsequent cache. The removed B must not survive a false apply.
            var published = [1_999_001, 1_999_002]
            if !applied { published = [Int(item.windowID)] }
            #expect(published == [1_999_001])
        }
    }
    @Test("An open panel can coexist with a physically collapsed divider")
    func panelPresentationIsNotDividerGeometry() {
        let section = MenuBarSection(name: .hidden)
        section.desiredState = .showSection
        section.controlItem.state = .hideSection
        #expect(!section.isHidden)
        #expect(section.isDividerCollapsed)
        #expect(!MenuBarItemManager.isMidSectionTransition(dividerWidth: 5016, isSectionCollapsed: section.isDividerCollapsed))
        section.controlItem.state = .showSection
        #expect(MenuBarItemManager.isMidSectionTransition(dividerWidth: 5016, isSectionCollapsed: section.isDividerCollapsed))
    }
    @Test("Fixture validation is restricted without a production app blacklist")
    func fixtureBoundary() {
        let ordinary = MenuBarItem.fixture(tag: .appItem(bundleID: "com.tencent.xinWeChat", title: "Item-0"), windowID: 1_999_004)
        #expect(!TrayBoxConfiguration.accepts(ordinary, fixtureOnly: true))
        #expect(TrayBoxConfiguration.accepts(ordinary, fixtureOnly: false))
        let fixture = MenuBarItem.fixture(tag: .appItem(bundleID: "local.miao.thaw-baseline-fixture", title: "thaw.baseline.fixture.A"), windowID: 1_999_005)
        #expect(TrayBoxConfiguration.accepts(fixture, fixtureOnly: true))
        let spoofed = MenuBarItem.fixture(tag: .appItem(bundleID: "local.unrelated", title: "thaw.baseline.fixture.A"), windowID: 1_999_006)
        #expect(!TrayBoxConfiguration.accepts(spoofed, fixtureOnly: true))
    }
    @Test("A recycled window ID must not target a different application's Item-0")
    func recycledWindowIdentity() {
        let old = MenuBarItem.fixture(tag: .appItem(bundleID: "local.fixture.a", title: "Item-0"), windowID: 1_999_007, sourcePID: 991)
        let recycled = MenuBarItem.fixture(tag: .appItem(bundleID: "local.fixture.b", title: "Item-0"), windowID: 1_999_007, sourcePID: 992)
        #expect(TrayBoxModel.matchesSnapshot(old, selected: old))
        #expect(!TrayBoxModel.matchesSnapshot(recycled, selected: old))
    }
    @Test("A drag and an in-flight move independently keep the panel open")
    func overlappingCloseGuards() {
        let model = TrayBoxModel()
        #expect(!model.keepsPanelOpen)
        model.dragging = true
        #expect(model.keepsPanelOpen)
        model.busy = true; model.dragging = false
        #expect(model.keepsPanelOpen)
        model.busy = false
        model.restoringMenu = true
        #expect(model.keepsPanelOpen)
        model.restoringMenu = false
        #expect(!model.keepsPanelOpen)
    }
    @Test("Position verification rejects a different display and blocked window")
    func nativePositionVerification() {
        let divider = CGRect(x: 500, y: 0, width: 20, height: 24)
        #expect(TrayBoxModel.isInSection(CGRect(x: 550, y: 0, width: 24, height: 24), divider: divider, section: .visible))
        #expect(TrayBoxModel.isInSection(CGRect(x: -1200, y: 0, width: 24, height: 24), divider: divider, section: .hidden))
        #expect(!TrayBoxModel.isInSection(CGRect(x: 550, y: 300, width: 24, height: 24), divider: divider, section: .visible))
        #expect(!TrayBoxModel.isInSection(CGRect(x: -1, y: 0, width: 24, height: 24), divider: divider, section: .hidden))
        #expect(!TrayBoxModel.isInSection(CGRect(x: 0, y: 0, width: 0, height: 24), divider: divider, section: .hidden))
    }
}
