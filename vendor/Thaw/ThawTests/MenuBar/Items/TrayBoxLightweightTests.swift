import Foundation
import Testing
@testable import Thaw

#if MIAOSHOU_COMPACT
@MainActor
struct TrayBoxLightweightTests {
    @Test
    func disabledUpdaterCannotBeEnabledOrOpenAFeed() {
        let manager = UpdatesManager()
        var opened = false
        manager.openURL = { _ in opened = true }
        manager.automaticallyChecksForUpdates = true
        manager.automaticallyDownloadsUpdates = true
        manager.startUpdaterIfNeeded()
        manager.checkForUpdates()
        manager.checkForAlphaUpdateAfterCompatibilityWarning()
        #expect(!manager.automaticallyChecksForUpdates)
        #expect(!manager.automaticallyDownloadsUpdates)
        #expect(!manager.canCheckForUpdates && manager.lastUpdateCheckDate == nil)
        #expect(!opened)
    }
}
#endif
