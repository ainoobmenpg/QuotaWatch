import SwiftUI

@main
struct QuotaWatchApp: App {
    var body: some Scene {
        MenuBarExtra("QuotaWatch", systemImage: "chart.bar") {
            MenuBarView()
        }
    }
}

struct MenuBarView: View {
    var body: some View {
        Text("Hello")
            .padding()
    }
}
