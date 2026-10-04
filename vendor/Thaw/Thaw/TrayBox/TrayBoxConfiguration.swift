// 菜单收纳 local integration. Full Thaw engine is retained under GPLv3.
import AppKit

@MainActor
enum TrayBoxConfiguration {
    static var isUnitTesting: Bool { ProcessInfo.processInfo.environment["TRAYBOX_UNIT_TESTS"] == "1" }
    static var fixtureOnly: Bool { CommandLine.arguments.contains("--fixture-only") || Bundle.main.object(forInfoDictionaryKey: "TrayBoxFixtureOnly") as? Bool == true }
    static var automaticPlacementAllowed: Bool {
        (Defaults.object(forKey: .automaticArrangementEnabled) as? Bool)
            ?? Defaults.DefaultValue.automaticArrangementEnabled
    }
    static func accepts(_ item: MenuBarItem, fixtureOnly: Bool = TrayBoxConfiguration.fixtureOnly) -> Bool {
        !fixtureOnly || (item.title?.hasPrefix("thaw.baseline.fixture.") == true
            && (item.tag.namespace.description == "local.miao.thaw-baseline-fixture"
                || item.sourceApplication?.bundleIdentifier == "local.miao.thaw-baseline-fixture"))
    }
    static func prepare() {
        guard !isUnitTesting else { return }
        let values: [String: Any] = [
            "UseIceBar": true, "AutoRehide": false, "ShowOnHover": false,
            "ShowOnScroll": false, "ShowOnClick": false, "ShowOnDoubleClick": false,
            "HideApplicationMenus": false, "EnableAlwaysHiddenSection": false,
            "ShowAllSectionsOnUserDrag": false, "EnableMenuBarItemOverflow": false,
            "automaticArrangementEnabled": false, "SUEnableAutomaticChecks": false,
            "SUAutomaticallyUpdate": false, "hasSeenUpdateConsent": true,
            "hasSeenOnboarding": true, "hasCompletedFirstLaunch": true
        ]
        for (key, value) in values { UserDefaults.standard.set(value, forKey: key) }
        // Preserve the old app's boundary on the first migration; never seed
        // every ordinary status item or replay a real user's icon layout.
        for (old, new) in [("traybox.v2.arrow", "Thaw.ControlItem.Visible"),
                           ("traybox.v2.spacer", "Thaw.ControlItem.Hidden")] {
            let key = "NSStatusItem Preferred Position \(new)"
            if UserDefaults.standard.object(forKey: key) == nil,
               let position = UserDefaults.standard.object(forKey: "NSStatusItem Preferred Position \(old)") {
                UserDefaults.standard.set(position, forKey: key)
            }
        }
    }
}
