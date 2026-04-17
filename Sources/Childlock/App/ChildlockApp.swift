import SwiftUI

#if !SWIFT_PACKAGE
@main
struct ChildlockApp: App {
    var body: some Scene {
        WindowGroup {
            ChildlockRootView()
        }
    }
}
#endif
