import SwiftUI

struct ToolsView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @State private var showAddTool = false
    @State private var selectedTool: Tool? = nil
    @State private var showFilters = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Tool Inventory")
                            .font(.displaySmall)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button { showAddTool = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentYellow)
                        }
                    }

                    // Status pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(label: "All", count: toolVM.tools.count, isSelected: toolVM.filterStatus == nil) {
                                toolVM.filterStatus = nil
                            }
                            ForEach(ToolStatus.allCases, id: \.self) { status in
                                FilterPill(label: status.displayName,
                                           count: toolVM.tools.filter { $0.status == status }.count,
                                           color: status.color,
                                           isSelected: toolVM.filterStatus == status) {
                                    toolVM.filterStatus = toolVM.filterStatus == status ? nil : status
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    // Search
                    TNTextField(placeholder: "Search tools...", text: $toolVM.searchText, icon: "magnifyingglass")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Tool list
                if toolVM.filteredTools.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "wrench.and.screwdriver", title: "No tools found",
                                   subtitle: "Add your first tool to get started tracking your inventory.")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(toolVM.filteredTools) { tool in
                                ToolCard(tool: tool)
                                    .onTapGesture { selectedTool = tool }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddTool) { AddToolView() }
        .sheet(item: $selectedTool) { tool in ToolDetailView(tool: tool) }
    }
}

struct FilterPill: View {
    let label: String
    let count: Int
    var color: Color = .accentYellow
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("\(count)")
                    .font(.label)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(isSelected ? color.opacity(0.3) : Color.divider.opacity(0.5)))
            }
            .foregroundColor(isSelected ? color : .textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(isSelected ? color.opacity(0.12) : Color.cardBg))
            .overlay(Capsule().stroke(isSelected ? color.opacity(0.4) : Color.divider, lineWidth: 1))
        }
    }
}

struct ToolCard: View {
    let tool: Tool
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tool.status.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: tool.status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(tool.status.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tool.name)
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    StatusBadge(status: tool.status)
                }
                Text(tool.category)
                    .font(.caption)
                    .foregroundColor(.accentBlue)

                HStack(spacing: 16) {
                    if let locId = tool.locationId {
                        Label(locationVM.name(for: locId), systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    if let wId = tool.workerId {
                        Label(workerVM.name(for: wId), systemImage: "person.circle")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Condition bar
                HStack(spacing: 6) {
                    Text("Condition:")
                        .font(.label)
                        .foregroundColor(.textInactive)
                    Text(tool.condition.rawValue)
                        .font(.label)
                        .foregroundColor(tool.condition.color)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
    }
}

// MARK: - Add Tool View
struct AddToolView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name = ""
    @State private var category = toolCategories[0]
    @State private var status = ToolStatus.available
    @State private var condition = ToolCondition.good
    @State private var selectedLocation: UUID? = nil
    @State private var selectedWorker: UUID? = nil
    @State private var serialNumber = ""
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TNTextField(placeholder: "Tool Name *", text: $name, icon: "wrench.fill")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.caption).foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(toolCategories, id: \.self) { cat in
                                    Button(cat) { category = cat }
                                        .font(.caption)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Capsule().fill(category == cat ? Color.accentYellow.opacity(0.2) : Color.cardBg))
                                        .foregroundColor(category == cat ? .accentYellow : .textSecondary)
                                        .overlay(Capsule().stroke(category == cat ? Color.accentYellow.opacity(0.4) : Color.divider, lineWidth: 1))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status").font(.caption).foregroundColor(.textSecondary)
                        Picker("Status", selection: $status) {
                            ForEach(ToolStatus.allCases, id: \.self) { s in
                                Text(s.displayName).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Condition").font(.caption).foregroundColor(.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(ToolCondition.allCases, id: \.self) { c in
                                Button(c.rawValue) { condition = c }
                                    .font(.caption)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(condition == c ? c.color.opacity(0.2) : Color.cardBg))
                                    .foregroundColor(condition == c ? c.color : .textSecondary)
                                    .overlay(Capsule().stroke(condition == c ? c.color.opacity(0.4) : Color.divider, lineWidth: 1))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location").font(.caption).foregroundColor(.textSecondary)
                        Picker("Location", selection: $selectedLocation) {
                            Text("None").tag(Optional<UUID>.none)
                            ForEach(locationVM.locations) { loc in
                                Text(loc.name).tag(Optional(loc.id))
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assigned Worker").font(.caption).foregroundColor(.textSecondary)
                        Picker("Worker", selection: $selectedWorker) {
                            Text("Unassigned").tag(Optional<UUID>.none)
                            ForEach(workerVM.activeWorkers) { w in
                                Text(w.name).tag(Optional(w.id))
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    }

                    TNTextField(placeholder: "Serial Number", text: $serialNumber, icon: "barcode")
                    TNTextField(placeholder: "Notes", text: $notes, icon: "note.text")

                    if showError {
                        Text("Tool name is required")
                            .font(.caption)
                            .foregroundColor(.statusError)
                    }

                    Button("Save Tool") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
                        var tool = Tool(name: name, category: category, status: status, condition: condition,
                                       locationId: selectedLocation, workerId: selectedWorker,
                                       serialNumber: serialNumber, notes: notes)
                        if tool.workerId != nil { tool.status = .inUse }
                        toolVM.add(tool)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Tool Detail View
struct ToolDetailView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @EnvironmentObject var maintenanceVM: MaintenanceViewModel
    @Environment(\.presentationMode) var dismiss

    var tool: Tool
    @State private var showEdit = false
    @State private var showAssign = false
    @State private var showAddMaintenance = false
    @State private var currentTool: Tool

    init(tool: Tool) {
        self.tool = tool
        _currentTool = State(initialValue: tool)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [currentTool.status.color.opacity(0.2), Color.cardBg], startPoint: .top, endPoint: .bottom))

                        VStack(spacing: 12) {
                            ZStack {
                                Circle().fill(currentTool.status.color.opacity(0.2)).frame(width: 80, height: 80)
                                Image(systemName: currentTool.status.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(currentTool.status.color)
                            }
                            Text(currentTool.name)
                                .font(.displaySmall)
                                .foregroundColor(.textPrimary)
                            StatusBadge(status: currentTool.status)
                            Text(currentTool.category)
                                .font(.caption)
                                .foregroundColor(.accentBlue)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 20)

                    // Quick status change
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Status").font(.caption).foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ToolStatus.allCases, id: \.self) { s in
                                    Button {
                                        toolVM.updateStatus(toolId: currentTool.id, status: s)
                                        if let updated = toolVM.tools.first(where: { $0.id == currentTool.id }) {
                                            currentTool = updated
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: s.icon).font(.caption)
                                            Text(s.displayName).font(.caption)
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Capsule().fill(currentTool.status == s ? s.color.opacity(0.2) : Color.cardBg))
                                        .foregroundColor(currentTool.status == s ? s.color : .textSecondary)
                                        .overlay(Capsule().stroke(currentTool.status == s ? s.color : Color.divider, lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Details
                    TNCard {
                        VStack(spacing: 14) {
                            DetailRow(label: "Condition", value: currentTool.condition.rawValue, valueColor: currentTool.condition.color)
                            Divider().background(Color.divider)
                            DetailRow(label: "Location", value: locationVM.name(for: currentTool.locationId))
                            Divider().background(Color.divider)
                            DetailRow(label: "Assigned To", value: workerVM.name(for: currentTool.workerId))
                            Divider().background(Color.divider)
                            DetailRow(label: "Serial #", value: currentTool.serialNumber.isEmpty ? "—" : currentTool.serialNumber)
                            if !currentTool.notes.isEmpty {
                                Divider().background(Color.divider)
                                DetailRow(label: "Notes", value: currentTool.notes)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Maintenance history
                    let history = maintenanceVM.records(for: currentTool.id)
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maintenance History").font(.headlineLarge).foregroundColor(.textPrimary)
                            ForEach(history.prefix(5)) { rec in
                                MaintenanceHistoryRow(record: rec)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button("Assign to Worker") { showAssign = true }
                            .buttonStyle(SecondaryButtonStyle())
                        Button("Mark as Returned") {
                            toolVM.markReturned(toolId: currentTool.id)
                            if let updated = toolVM.tools.first(where: { $0.id == currentTool.id }) {
                                currentTool = updated
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        Button("Add Maintenance") { showAddMaintenance = true }
                            .buttonStyle(SecondaryButtonStyle())
                        Button("Delete Tool") {
                            toolVM.delete(currentTool)
                            dismiss.wrappedValue.dismiss()
                        }
                        .buttonStyle(DangerButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Tool Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showEdit = true }
                        .foregroundColor(.accentYellow)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditToolView(tool: currentTool) }
        .sheet(isPresented: $showAssign) { AssignWorkerView(tool: currentTool) }
        .sheet(isPresented: $showAddMaintenance) { AddMaintenanceView(toolId: currentTool.id) }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .textPrimary
    var body: some View {
        HStack {
            Text(label).font(.bodySmall).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.headlineSmall).foregroundColor(valueColor)
        }
    }
}

struct MaintenanceHistoryRow: View {
    let record: MaintenanceRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gear.circle.fill").foregroundColor(.accentOrange).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.rawValue).font(.headlineSmall).foregroundColor(.textPrimary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundColor(.textSecondary)
            }
            Spacer()
            if record.cost > 0 {
                Text("$\(String(format: "%.0f", record.cost))").font(.headlineSmall).foregroundColor(.accentYellow)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
    }
}

// MARK: - Edit Tool
struct EditToolView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name: String
    @State private var category: String
    @State private var status: ToolStatus
    @State private var condition: ToolCondition
    @State private var selectedLocation: UUID?
    @State private var selectedWorker: UUID?
    @State private var serialNumber: String
    @State private var notes: String
    private let originalTool: Tool

    init(tool: Tool) {
        originalTool = tool
        _name = State(initialValue: tool.name)
        _category = State(initialValue: tool.category)
        _status = State(initialValue: tool.status)
        _condition = State(initialValue: tool.condition)
        _selectedLocation = State(initialValue: tool.locationId)
        _selectedWorker = State(initialValue: tool.workerId)
        _serialNumber = State(initialValue: tool.serialNumber)
        _notes = State(initialValue: tool.notes)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TNTextField(placeholder: "Tool Name", text: $name, icon: "wrench.fill")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status").font(.caption).foregroundColor(.textSecondary)
                        Picker("Status", selection: $status) {
                            ForEach(ToolStatus.allCases, id: \.self) { s in Text(s.displayName).tag(s) }
                        }.pickerStyle(.segmented)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Condition").font(.caption).foregroundColor(.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(ToolCondition.allCases, id: \.self) { c in
                                Button(c.rawValue) { condition = c }
                                    .font(.caption).padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(condition == c ? c.color.opacity(0.2) : Color.cardBg))
                                    .foregroundColor(condition == c ? c.color : .textSecondary)
                                    .overlay(Capsule().stroke(condition == c ? c.color : Color.divider, lineWidth: 1))
                            }
                        }
                    }
                    Picker("Location", selection: $selectedLocation) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(locationVM.locations) { l in Text(l.name).tag(Optional(l.id)) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                    Picker("Worker", selection: $selectedWorker) {
                        Text("Unassigned").tag(Optional<UUID>.none)
                        ForEach(workerVM.activeWorkers) { w in Text(w.name).tag(Optional(w.id)) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                    TNTextField(placeholder: "Serial Number", text: $serialNumber, icon: "barcode")
                    TNTextField(placeholder: "Notes", text: $notes, icon: "note.text")

                    Button("Save Changes") {
                        var updated = originalTool
                        updated.name = name; updated.category = category; updated.status = status
                        updated.condition = condition; updated.locationId = selectedLocation
                        updated.workerId = selectedWorker; updated.serialNumber = serialNumber; updated.notes = notes
                        toolVM.update(updated)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Edit Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Assign Worker
struct AssignWorkerView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @Environment(\.presentationMode) var dismiss
    let tool: Tool
    @State private var selectedWorker: UUID? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    Button("Unassign") {
                        toolVM.assignWorker(toolId: tool.id, workerId: nil)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    ForEach(workerVM.activeWorkers) { worker in
                        Button {
                            toolVM.assignWorker(toolId: tool.id, workerId: worker.id)
                            dismiss.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.accentBlue.opacity(0.15)).frame(width: 44, height: 44)
                                    Text(String(worker.name.prefix(1)))
                                        .font(.headlineLarge).foregroundColor(.accentBlue)
                                }
                                VStack(alignment: .leading) {
                                    Text(worker.name).font(.headlineLarge).foregroundColor(.textPrimary)
                                    Text(worker.role).font(.caption).foregroundColor(.textSecondary)
                                }
                                Spacer()
                                if tool.workerId == worker.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.statusGood)
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(tool.workerId == worker.id ? Color.statusGood : Color.divider, lineWidth: 1))
                        }
                    }
                }
                .padding(20).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Assign to Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Add Maintenance
struct AddMaintenanceView: View {
    @EnvironmentObject var maintenanceVM: MaintenanceViewModel
    @EnvironmentObject var toolVM: ToolViewModel
    @Environment(\.presentationMode) var dismiss
    let toolId: UUID

    @State private var type = MaintenanceType.inspection
    @State private var description = ""
    @State private var performedBy = ""
    @State private var cost = ""
    @State private var date = Date()
    @State private var nextDueDate = Date()
    @State private var hasNextDue = false
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type").font(.caption).foregroundColor(.textSecondary)
                        Picker("Type", selection: $type) {
                            ForEach(MaintenanceType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }.pickerStyle(.wheel).frame(height: 100)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    }
                    TNTextField(placeholder: "Description *", text: $description, icon: "text.alignleft")
                    TNTextField(placeholder: "Performed By", text: $performedBy, icon: "person.fill")
                    TNTextField(placeholder: "Cost", text: $cost, icon: "dollarsign.circle")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundColor(.textPrimary)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    Toggle("Set Next Due Date", isOn: $hasNextDue)
                        .foregroundColor(.textPrimary)
                        .toggleStyle(SwitchToggleStyle(tint: .accentYellow))
                        .padding(.horizontal, 4)
                    if hasNextDue {
                        DatePicker("Next Due", selection: $nextDueDate, displayedComponents: .date)
                            .foregroundColor(.textPrimary)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    }
                    TNTextField(placeholder: "Notes", text: $notes, icon: "note.text")

                    Button("Save Maintenance Record") {
                        guard !description.isEmpty else { return }
                        let rec = MaintenanceRecord(
                            toolId: toolId, type: type, description: description,
                            performedBy: performedBy, cost: Double(cost) ?? 0,
                            date: date, nextDueDate: hasNextDue ? nextDueDate : nil, notes: notes
                        )
                        maintenanceVM.add(rec)
                        toolVM.updateStatus(toolId: toolId, status: .available)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}
