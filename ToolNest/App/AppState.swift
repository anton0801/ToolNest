import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("themeMode") var themeMode: String = "dark" {
        didSet { updateColorScheme() }
    }
    @AppStorage("currencySymbol") var currencySymbol: String = "$"
    @AppStorage("unitSystem") var unitSystem: String = "metric"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("lowStockThreshold") var lowStockThreshold: Int = 5

    @Published var colorScheme: ColorScheme? = .dark
    @Published var showSplash: Bool = true

    init() {
        updateColorScheme()
    }

    private func updateColorScheme() {
        switch themeMode {
        case "light": colorScheme = .light
        case "dark": colorScheme = .dark
        default: colorScheme = nil
        }
    }
}
