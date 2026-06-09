import SwiftUI

struct TasksView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @EnvironmentObject var toolVM: ToolViewModel
    @State private var selectedFilter = TaskFilter.all
    @State private var showAdd = false
    @State private var selectedTask: AppTask? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tasks")
                                .font(.displaySmall)
                                .foregroundColor(.textPrimary)
                            Text("\(taskVM.pendingCount) pending")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Button { showAdd = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentYellow)
                        }
                    }

                    // Filter tabs
                    HStack(spacing: 0) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                let count = taskVM.filtered(by: filter).count
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(filter.rawValue).font(.caption).fontWeight(selectedFilter == filter ? .semibold : .regular)
                                        if count > 0 {
                                            Text("\(count)").font(.label)
                                                .padding(.horizontal, 5).padding(.vertical, 1)
                                                .background(Capsule().fill(selectedFilter == filter ? Color.accentYellow.opacity(0.3) : Color.divider.opacity(0.5)))
                                        }
                                    }
                                    .foregroundColor(selectedFilter == filter ? .accentYellow : .textInactive)
                                    Rectangle()
                                        .fill(selectedFilter == filter ? Color.accentYellow : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .overlay(Rectangle().fill(Color.divider).frame(height: 1), alignment: .bottom)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                // Task list
                let tasks = taskVM.filtered(by: selectedFilter)
                if tasks.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "checklist", title: "No tasks",
                                   subtitle: selectedFilter == .done ? "Complete some tasks to see them here." : "All clear! Add tasks to stay on top of your work.")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(tasks) { task in
                                TaskRow(task: task)
                                    .onTapGesture { selectedTask = task }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAdd) { AddTaskView() }
        .sheet(item: $selectedTask) { task in TaskDetailView(task: task) }
    }
}

struct TaskRow: View {
    let task: AppTask
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var workerVM: WorkerViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Complete button
            Button {
                if task.status != .done {
                    taskVM.markDone(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.status == .done ? Color.statusGood : task.priority.color, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if task.status == .done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.statusGood)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headlineLarge)
                        .foregroundColor(task.status == .done ? .textInactive : .textPrimary)
                        .strikethrough(task.status == .done)
                    Spacer()
                    StatusPill(text: task.priority.rawValue, color: task.priority.color)
                }
                if !task.description.isEmpty {
                    Text(task.description).font(.caption).foregroundColor(.textSecondary).lineLimit(1)
                }
                HStack(spacing: 12) {
                    if let due = task.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .statusError : .textSecondary)
                    }
                    if let wId = task.workerId {
                        Label(workerVM.name(for: wId), systemImage: "person")
                            .font(.caption).foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(task.isOverdue ? Color.statusError.opacity(0.4) : Color.divider, lineWidth: 1))
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @EnvironmentObject var toolVM: ToolViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedWorker: UUID? = nil
    @State private var selectedTool: UUID? = nil
    @State private var showError = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TNTextField(placeholder: "Task Title *", text: $title, icon: "checklist")
                    TNTextField(placeholder: "Description", text: $description, icon: "text.alignleft")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority").font(.caption).foregroundColor(.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button(p.rawValue) { priority = p }
                                    .font(.caption).padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(priority == p ? p.color.opacity(0.2) : Color.cardBg))
                                    .foregroundColor(priority == p ? p.color : .textSecondary)
                                    .overlay(Capsule().stroke(priority == p ? p.color : Color.divider, lineWidth: 1))
                            }
                        }
                    }

                    Toggle("Set Due Date", isOn: $hasDueDate)
                        .foregroundColor(.textPrimary)
                        .toggleStyle(SwitchToggleStyle(tint: .accentYellow))
                        .padding(.horizontal, 4)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .foregroundColor(.textPrimary)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    }

                    Picker("Assign Worker", selection: $selectedWorker) {
                        Text("Unassigned").tag(Optional<UUID>.none)
                        ForEach(workerVM.activeWorkers) { w in Text(w.name).tag(Optional(w.id)) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                    Picker("Related Tool", selection: $selectedTool) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(toolVM.tools) { t in Text(t.name).tag(Optional(t.id)) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                    if showError { Text("Task title is required").font(.caption).foregroundColor(.statusError) }

                    Button("Add Task") {
                        guard !title.isEmpty else { showError = true; return }
                        let task = AppTask(
                            title: title, description: description,
                            priority: priority, status: .todo,
                            dueDate: hasDueDate ? dueDate : nil,
                            toolId: selectedTool, workerId: selectedWorker
                        )
                        taskVM.add(task)
                        if notificationsEnabled && hasDueDate {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                                if granted { taskVM.scheduleNotification(for: task) }
                            }
                        }
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var workerVM: WorkerViewModel
    @EnvironmentObject var toolVM: ToolViewModel
    @Environment(\.presentationMode) var dismiss
    var task: AppTask

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status hero
                    TNCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                StatusPill(text: task.priority.rawValue, color: task.priority.color)
                                Spacer()
                                StatusPill(text: task.status.rawValue,
                                           color: task.status == .done ? .statusGood : task.isOverdue ? .statusError : .accentBlue)
                            }
                            Text(task.title).font(.displaySmall).foregroundColor(.textPrimary)
                            if !task.description.isEmpty {
                                Text(task.description).font(.bodyLarge).foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    TNCard {
                        VStack(spacing: 14) {
                            if let due = task.dueDate {
                                DetailRow(label: "Due Date",
                                          value: due.formatted(date: .abbreviated, time: .shortened),
                                          valueColor: task.isOverdue ? .statusError : .textPrimary)
                                Divider().background(Color.divider)
                            }
                            DetailRow(label: "Assigned To", value: workerVM.name(for: task.workerId))
                            Divider().background(Color.divider)
                            if let toolId = task.toolId, let t = toolVM.tools.first(where: { $0.id == toolId }) {
                                DetailRow(label: "Related Tool", value: t.name)
                                Divider().background(Color.divider)
                            }
                            DetailRow(label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .omitted))
                            if let done = task.completedAt {
                                Divider().background(Color.divider)
                                DetailRow(label: "Completed", value: done.formatted(date: .abbreviated, time: .omitted), valueColor: .statusGood)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        if task.status != .done {
                            Button("Mark as Done") {
                                taskVM.markDone(task)
                                dismiss.wrappedValue.dismiss()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        Button("Delete Task") {
                            taskVM.delete(task)
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
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}
