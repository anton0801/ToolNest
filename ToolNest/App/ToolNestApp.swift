import SwiftUI

@main
struct ToolNestApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var toolVM = ToolViewModel()
    @StateObject private var consumableVM = ConsumableViewModel()
    @StateObject private var locationVM = LocationViewModel()
    @StateObject private var workerVM = WorkerViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var maintenanceVM = MaintenanceViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(toolVM)
                .environmentObject(consumableVM)
                .environmentObject(locationVM)
                .environmentObject(workerVM)
                .environmentObject(taskVM)
                .environmentObject(maintenanceVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
