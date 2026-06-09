import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @EnvironmentObject var maintenanceVM: MaintenanceViewModel

    @State private var showLocations = false
    @State private var showWorkers = false
    @State private var showClearDataAlert = false
    @State private var showSaveConfirmation = false
    @State private var notificationStatus = ""

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.displaySmall)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Theme
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 0) {
                            SettingRow(label: "Theme") {
                                Picker("Theme", selection: $appState.themeMode) {
                                    Text("Dark").tag("dark")
                                    Text("Light").tag("light")
                                    Text("System").tag("system")
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 180)
                            }
                        }
                    }

                    // Preferences
                    SettingsSection(title: "Preferences") {
                        VStack(spacing: 0) {
                            SettingRow(label: "Currency") {
                                Picker("Currency", selection: $appState.currencySymbol) {
                                    Text("$ USD").tag("$")
                                    Text("€ EUR").tag("€")
                                    Text("£ GBP").tag("£")
                                    Text("¥ JPY").tag("¥")
                                    Text("₽ RUB").tag("₽")
                                }
                                .foregroundColor(.textSecondary)
                                .accentColor(.accentYellow)
                            }
                            Divider().background(Color.divider).padding(.leading, 20)
                            SettingRow(label: "Units") {
                                Picker("Units", selection: $appState.unitSystem) {
                                    Text("Metric").tag("metric")
                                    Text("Imperial").tag("imperial")
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 160)
                            }
                            Divider().background(Color.divider).padding(.leading, 20)
                            SettingRow(label: "Low Stock Threshold") {
                                Stepper("\(appState.lowStockThreshold)", value: $appState.lowStockThreshold, in: 1...50)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }

                    // Notifications
                    SettingsSection(title: "Notifications") {
                        VStack(spacing: 0) {
                            SettingRow(label: "Enable Notifications") {
                                Toggle("", isOn: $appState.notificationsEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentYellow))
                                    .onChange(of: appState.notificationsEnabled) { enabled in
                                        if enabled {
                                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                                DispatchQueue.main.async {
                                                    notificationStatus = granted ? "Enabled" : "Denied in Settings"
                                                    appState.notificationsEnabled = granted
                                                }
                                            }
                                        } else {
                                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                            notificationStatus = "Disabled"
                                        }
                                    }
                            }
                            if !notificationStatus.isEmpty {
                                Text("Status: \(notificationStatus)")
                                    .font(.caption)
                                    .foregroundColor(notificationStatus == "Enabled" ? .statusGood : .statusWarning)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                        }
                    }

                    // Locations & Workers
                    SettingsSection(title: "Data Management") {
                        VStack(spacing: 0) {
                            Button { showLocations = true } label: {
                                SettingNavRow(icon: "mappin.circle.fill", label: "Manage Locations",
                                              value: "\(locationVM.locations.count)", color: .accentBlue)
                            }
                            Divider().background(Color.divider).padding(.leading, 56)
                            Button { showWorkers = true } label: {
                                SettingNavRow(icon: "person.2.fill", label: "Manage Workers",
                                              value: "\(workerVM.workers.count)", color: .accentOrange)
                            }
                        }
                    }

                    // Stats
                    SettingsSection(title: "Database") {
                        VStack(spacing: 0) {
                            SettingRow(label: "Total Tools") {
                                Text("\(toolVM.tools.count)").font(.headlineSmall).foregroundColor(.textPrimary)
                            }
                            Divider().background(Color.divider).padding(.leading, 20)
                            SettingRow(label: "Total Consumables") {
                                Text("\(consumableVM.consumables.count)").font(.headlineSmall).foregroundColor(.textPrimary)
                            }
                            Divider().background(Color.divider).padding(.leading, 20)
                            SettingRow(label: "Total Tasks") {
                                Text("\(taskVM.tasks.count)").font(.headlineSmall).foregroundColor(.textPrimary)
                            }
                            Divider().background(Color.divider).padding(.leading, 20)
                            SettingRow(label: "Maintenance Records") {
                                Text("\(maintenanceVM.records.count)").font(.headlineSmall).foregroundColor(.textPrimary)
                            }
                        }
                    }

                    // Danger zone
                    SettingsSection(title: "Danger Zone") {
                        Button {
                            showClearDataAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill").foregroundColor(.statusError)
                                Text("Reset All Data").foregroundColor(.statusError).font(.headlineLarge)
                                Spacer()
                            }
                            .padding(16)
                        }
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text("Tool Nest v1.0.0")
                            .font(.caption)
                            .foregroundColor(.textInactive)
                        Text("Built for professionals who build things.")
                            .font(.caption)
                            .foregroundColor(.textInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.bgPrimary)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLocations) { LocationsManageView() }
        .sheet(isPresented: $showWorkers) { WorkersManageView() }
        .alert("Reset All Data", isPresented: $showClearDataAlert) {
            Button("Reset Everything", role: .destructive) {
                toolVM.tools = []
                consumableVM.consumables = []
                taskVM.tasks = []
                maintenanceVM.records = []
                locationVM.locations = []
                workerVM.workers = []
                appState.hasCompletedOnboarding = false
                // Clear all persisted data
                ["tools_data","consumables_data","tasks_data","maintenance_data","locations_data","workers_data"].forEach {
                    UserDefaults.standard.removeObject(forKey: $0)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all tools, consumables, tasks, and records. This cannot be undone.")
        }
        .overlay(
            showSaveConfirmation ? VStack {
                Spacer()
                Text("✓ Settings Saved").font(.headlineSmall).foregroundColor(.bgPrimary)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentYellow))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 120)
            } : nil
        )
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    var content: () -> Content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.label).foregroundColor(.textInactive).tracking(1)
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBg))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }
}

struct SettingRow<Content: View>: View {
    let label: String
    var content: () -> Content
    init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label; self.content = content
    }
    var body: some View {
        HStack(spacing: 12) {
            Text(label).font(.bodyLarge).foregroundColor(.textPrimary)
            Spacer()
            content()
        }
        .padding(16)
    }
}

struct SettingNavRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(label).font(.bodyLarge).foregroundColor(.textPrimary)
            Spacer()
            Text(value).font(.headlineSmall).foregroundColor(.textSecondary)
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.textInactive)
        }
        .padding(16)
    }
}

// MARK: - Locations Manage
struct LocationsManageView: View {
    @EnvironmentObject var locationVM: LocationViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var showAdd = false
    @State private var name = ""
    @State private var type = "Storage"
    @State private var address = ""
    @State private var notes = ""

    let types = ["Storage", "Construction", "Workshop", "Office", "Other"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Add form
                    TNCard {
                        VStack(spacing: 12) {
                            Text("Add Location").font(.headlineLarge).foregroundColor(.textPrimary)
                            TNTextField(placeholder: "Location Name", text: $name, icon: "mappin.circle")
                            HStack(spacing: 8) {
                                ForEach(types, id: \.self) { t in
                                    Button(t) { type = t }
                                        .font(.label).padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(Capsule().fill(type == t ? Color.accentBlue.opacity(0.2) : Color.bgSoft))
                                        .foregroundColor(type == t ? .accentBlue : .textSecondary)
                                        .overlay(Capsule().stroke(type == t ? Color.accentBlue : Color.divider, lineWidth: 1))
                                }
                            }
                            TNTextField(placeholder: "Address", text: $address, icon: "map")
                            TNTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                            Button("Add Location") {
                                guard !name.isEmpty else { return }
                                locationVM.add(Location(name: name, type: type, address: address, notes: notes))
                                name = ""; address = ""; notes = ""
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)

                    ForEach(locationVM.locations) { loc in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.accentBlue.opacity(0.15)).frame(width: 40, height: 40)
                                Image(systemName: "mappin.circle.fill").foregroundColor(.accentBlue)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.name).font(.headlineLarge).foregroundColor(.textPrimary)
                                Text(loc.type + (loc.address.isEmpty ? "" : " · " + loc.address))
                                    .font(.caption).foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Button {
                                locationVM.delete(loc)
                            } label: {
                                Image(systemName: "trash").foregroundColor(.statusError)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentYellow)
                }
            }
        }
    }
}

// MARK: - Workers Manage
struct WorkersManageView: View {
    @EnvironmentObject var workerVM: WorkerViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var role = ""
    @State private var phone = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    TNCard {
                        VStack(spacing: 12) {
                            Text("Add Worker").font(.headlineLarge).foregroundColor(.textPrimary)
                            TNTextField(placeholder: "Full Name", text: $name, icon: "person.fill")
                            TNTextField(placeholder: "Role", text: $role, icon: "briefcase.fill")
                            TNTextField(placeholder: "Phone", text: $phone, icon: "phone.fill")
                            Button("Add Worker") {
                                guard !name.isEmpty else { return }
                                workerVM.add(Worker(name: name, role: role, phone: phone, notes: ""))
                                name = ""; role = ""; phone = ""
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)

                    ForEach(workerVM.workers) { w in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.accentOrange.opacity(0.15)).frame(width: 44, height: 44)
                                Text(String(w.name.prefix(1))).font(.headlineLarge).foregroundColor(.accentOrange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(w.name).font(.headlineLarge).foregroundColor(.textPrimary)
                                Text(w.role.isEmpty ? "No role" : w.role).font(.caption).foregroundColor(.textSecondary)
                                if !w.phone.isEmpty {
                                    Text(w.phone).font(.caption).foregroundColor(.accentBlue)
                                }
                            }
                            Spacer()
                            Button {
                                workerVM.delete(w)
                            } label: {
                                Image(systemName: "trash").foregroundColor(.statusError)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Workers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentYellow)
                }
            }
        }
    }
}
