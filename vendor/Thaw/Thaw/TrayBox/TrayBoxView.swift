import SwiftUI
import UniformTypeIdentifiers

struct TrayBoxView: View {
    @Bindable var model: TrayBoxModel
    @State private var hiddenTargeted = false
    @State private var visibleTargeted = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("秒收").font(.headline)
                Spacer()
                Button(model.editing ? "完成" : "整理") { model.editing.toggle() }
                    .buttonStyle(.borderless).disabled(model.keepsPanelOpen)
                Button { Task { await model.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless).help("刷新图标").accessibilityLabel("刷新图标")
                    .disabled(model.keepsPanelOpen)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    group(.hidden, title: "已收纳")
                    if model.editing { Divider(); group(.visible, title: "顶栏") }
                }.padding(2)
            }.scrollIndicators(.automatic)
            Divider()
            HStack(alignment: .top, spacing: 8) {
                if model.busy { ProgressView().controlSize(.small) }
                Text(model.message).font(.caption).foregroundStyle(model.hasError ? .orange : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(minHeight: 30, alignment: .topLeading)
        }
        .padding(16).frame(width: 368, height: model.editing ? 490 : 330)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.separator, lineWidth: 0.5))
    }
    private func group(_ section: MenuBarSection.Name, title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.editing { Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary) }
            let items = model.items(in: section)
            if items.isEmpty {
                Text(section == .hidden ? "这里还没有图标，点整理收进来" : "可移动的顶栏图标会显示在这里")
                    .font(.callout).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 80)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(items, id: \.windowID) { item in
                    VStack(spacing: 5) {
                        TrayBoxIcon(model: model, item: item).frame(width: 48, height: 40)
                            .contextMenu {
                                Button(section == .hidden ? "放回顶栏" : "收进来") {
                                    Task { await model.move(item, to: section == .hidden ? .visible : .hidden) }
                                }.disabled(model.busy || !item.isMovableAddressingWindowOwner)
                                Button("打开原应用菜单") { Task { await model.openMenu(item) } }
                            }
                        Text(model.name(for: item)).font(.caption).lineLimit(1).truncationMode(.tail)
                        if model.editing {
                            Button(section == .hidden ? "↑ 放回" : "↓ 收进") {
                                Task { await model.move(item, to: section == .hidden ? .visible : .hidden) }
                            }
                            .font(.caption).controlSize(.mini)
                            .accessibilityLabel("\(model.name(for: item))，\(section == .hidden ? "放回顶栏" : "收进来")")
                            .disabled(model.busy || !item.isMovableAddressingWindowOwner)
                        }
                    }.frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(
            (section == .hidden ? hiddenTargeted : visibleTargeted)
                ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.035)))
        .contentShape(Rectangle())
        .onDrop(of: [UTType.utf8PlainText], isTargeted: section == .hidden ? $hiddenTargeted : $visibleTargeted) { providers in
            guard !model.busy, let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: String.self) { token, _ in
                Task { @MainActor in
                    guard let token, token.hasPrefix("traybox:"),
                          let id = UInt32(token.dropFirst(8)),
                          let item = (model.items(in: .hidden) + model.items(in: .visible)).first(where: { $0.windowID == id }) else { return }
                    await model.move(item, to: section)
                }
            }
            return true
        }
    }
}

private struct TrayBoxIcon: NSViewRepresentable {
    let model: TrayBoxModel
    let item: MenuBarItem
    func makeNSView(context: Context) -> TrayBoxIconView { TrayBoxIconView() }
    func updateNSView(_ view: TrayBoxIconView, context: Context) {
        view.model = model; view.item = item
        view.icon = model.image(for: item)
        view.setAccessibilityLabel(model.name(for: item))
        view.toolTip = model.name(for: item)
        view.needsDisplay = true
    }
}

private final class TrayBoxIconView: NSView, NSDraggingSource {
    weak var model: TrayBoxModel?
    var item: MenuBarItem?
    var icon: NSImage?
    private var down: NSEvent?
    private var startedDrag = false
    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true); setAccessibilityRole(.button)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        if down != nil {
            NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
        }
        let image = icon ?? NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)
        image?.draw(in: imageRect(for: image),
                    from: .zero, operation: .sourceOver, fraction: model?.busy == true ? 0.4 : 1)
    }
    private func imageRect(for image: NSImage?) -> NSRect {
        let size = image?.size ?? NSSize(width: 24, height: 24)
        let scale = min(44 / max(size.width, 1), 28 / max(size.height, 1))
        let fitted = NSSize(width: size.width * scale, height: size.height * scale)
        return NSRect(x: (bounds.width - fitted.width) / 2, y: (bounds.height - fitted.height) / 2,
                      width: fitted.width, height: fitted.height)
    }
    override func mouseDown(with event: NSEvent) {
        guard model?.busy != true else { return }
        down = event; startedDrag = false; needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        defer { down = nil; needsDisplay = true }
        if !startedDrag, down != nil, bounds.contains(convert(event.locationInWindow, from: nil)) {
            _ = accessibilityPerformPress()
        }
    }
    override func accessibilityPerformPress() -> Bool {
        guard let model, let item, !model.busy else { return false }
        Task { await model.openMenu(item) }; return true
    }
    override func mouseDragged(with event: NSEvent) {
        guard let down, !startedDrag, let item, let model, !model.busy,
              item.isMovableAddressingWindowOwner,
              hypot(event.locationInWindow.x - down.locationInWindow.x,
                    event.locationInWindow.y - down.locationInWindow.y) >= 4 else { return }
        startedDrag = true; model.dragging = true
        let value = NSPasteboardItem(); value.setString("traybox:\(item.windowID)", forType: .string)
        let dragged = NSDraggingItem(pasteboardWriter: value)
        let image = icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)!
        dragged.setDraggingFrame(imageRect(for: image), contents: image)
        beginDraggingSession(with: [dragged], event: down, source: self)
    }
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .move }
    func draggingSession(_ session: NSDraggingSession, endedAt point: NSPoint, operation: NSDragOperation) {
        guard let model else { return }
        down = nil; needsDisplay = true
        // Release the hold after the destination has accepted its async move.
        Task { @MainActor in
            if operation.isEmpty, let item,
               NSScreen.screens.contains(where: { $0.frame.contains(point) && point.y >= $0.frame.maxY - $0.getMenuBarHeightEstimate() }) {
                await model.move(item, to: .visible)
            }
            model.dragging = false
        }
    }
}

final class TrayBoxHostingView: NSHostingView<TrayBoxView> {
    override func layout() {
        super.layout()
        (window as? IceBarPanel)?.resizeToContent()
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
