import SwiftUI
import AppKit

@main
struct QuotaWatchApp: App {
    // NSApplicationDelegateAdaptor で AppDelegate を接続
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var onboardingManager = OnboardingManager()

    var body: some Scene {
        // MenuBarExtra は使用しない（NSStatusItem のみを使用）
        // 空の WindowGroup を設定
        WindowGroup(id: "empty-window") {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)

        // オンボーディングウィンドウ
        WindowGroup(id: "onboarding-window") {
            VStack {
                if onboardingManager.needsOnboarding {
                    OnboardingView(
                        onComplete: {
                            Task {
                                await onboardingManager.markCompleted()
                                // Engineをセットアップ
                                await appDelegate.setupEngine()
                            }
                        },
                        onDismiss: {
                            // 後で設定を選んだ場合、アプリを終了
                            NSApplication.shared.terminate(nil)
                        }
                    )
                    .onAppear {
                        Task {
                            await LoggerManager.shared.log("オンボーディングシートを表示", category: "APP")
                        }
                    }
                } else {
                    EmptyView()
                }
            }
            .frame(width: 400, height: 300)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // APIキー設定シート
        Settings {
            if appDelegate.showingAPIKeySheet {
                APIKeySettingsSheet(
                    onSave: { apiKey in
                        await appDelegate.saveAPIKey(apiKey)
                    },
                    initialError: appDelegate.apiKeySaveError
                )
                .onDisappear {
                    appDelegate.showingAPIKeySheet = false
                }
            } else {
                EmptyView()
            }
        }
    }
}
