import SwiftUI

@main
struct card_testApp: App {
    init() {
        init_offsets()
        _ = ExploitManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
