import Foundation
import UserNotifications

// MARK: - LocationViewModel
class LocationViewModel: ObservableObject {
    @Published var locations: [Location] = []
    private let key = "locations_data"

    init() { load() }

    func add(_ loc: Location) { locations.append(loc); save() }
    func update(_ loc: Location) {
        if let idx = locations.firstIndex(where: { $0.id == loc.id }) { locations[idx] = loc; save() }
    }
    func delete(_ loc: Location) { locations.removeAll { $0.id == loc.id }; save() }

    func name(for id: UUID?) -> String {
        guard let id = id else { return "—" }
        return locations.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private func save() {
        if let data = try? JSONEncoder().encode(locations) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Location].self, from: data) else {
            loadSample(); return
        }
        locations = decoded
    }
    private func loadSample() {
        locations = [
            Location(name: "Warehouse A", type: "Storage", address: "Main St 1", notes: "Primary storage"),
            Location(name: "Site B", type: "Construction", address: "Oak Ave 24", notes: "Active project"),
            Location(name: "Workshop", type: "Workshop", address: "Industrial Rd 5", notes: "Repairs here"),
        ]
        save()
    }
}

// MARK: - WorkerViewModel
class WorkerViewModel: ObservableObject {
    @Published var workers: [Worker] = []
    private let key = "workers_data"

    init() { load() }

    func add(_ w: Worker) { workers.append(w); save() }
    func update(_ w: Worker) {
        if let idx = workers.firstIndex(where: { $0.id == w.id }) { workers[idx] = w; save() }
    }
    func delete(_ w: Worker) { workers.removeAll { $0.id == w.id }; save() }

    func name(for id: UUID?) -> String {
        guard let id = id else { return "Unassigned" }
        return workers.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    var activeWorkers: [Worker] { workers.filter { $0.isActive } }

    private func save() {
        if let data = try? JSONEncoder().encode(workers) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Worker].self, from: data) else {
            loadSample(); return
        }
        workers = decoded
    }
    private func loadSample() {
        workers = [
            Worker(name: "Alex Johnson", role: "Lead Carpenter", phone: "+1-555-0101", notes: ""),
            Worker(name: "Maria Garcia", role: "Electrician", phone: "+1-555-0102", notes: "Certified"),
            Worker(name: "Tom Wilson", role: "Plumber", phone: "+1-555-0103", notes: ""),
        ]
        save()
    }
}

// MARK: - TaskViewModel
class TaskViewModel: ObservableObject {
    @Published var tasks: [AppTask] = []
    private let key = "tasks_data"

    init() { load() }

    var todayTasks: [AppTask] { tasks.filter { $0.isToday && $0.status != .done } }
    var overdueTasks: [AppTask] { tasks.filter { $0.isOverdue } }
    var pendingCount: Int { tasks.filter { $0.status != .done }.count }

    func add(_ task: AppTask) { tasks.append(task); save() }
    func update(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) { tasks[idx] = task; save() }
    }
    func delete(_ task: AppTask) { tasks.removeAll { $0.id == task.id }; save() }

    func markDone(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].status = .done
            tasks[idx].completedAt = Date()
            save()
        }
    }

    func filtered(by filter: TaskFilter) -> [AppTask] {
        switch filter {
        case .all: return tasks
        case .today: return tasks.filter { $0.isToday }
        case .overdue: return tasks.filter { $0.isOverdue }
        case .done: return tasks.filter { $0.status == .done }
        }
    }

    func scheduleNotification(for task: AppTask) {
        guard let due = task.dueDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title)"
        content.body = task.description.isEmpty ? "Check your task list." : task.description
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([AppTask].self, from: data) else {
            loadSample(); return
        }
        tasks = decoded
        updateOverdue()
    }
    private func updateOverdue() {
        for i in tasks.indices {
            if tasks[i].isOverdue && tasks[i].status == .todo { tasks[i].status = .overdue }
        }
    }
    private func loadSample() {
        let cal = Calendar.current
        tasks = [
            AppTask(title: "Replace drill battery", description: "Bosch drill needs new 18V battery", priority: .high, status: .todo, dueDate: cal.date(byAdding: .day, value: 1, to: Date())),
            AppTask(title: "Clean angle grinder", description: "After repair, clean and oil", priority: .medium, status: .inProgress),
            AppTask(title: "Order sandpaper P80", description: "Low stock alert", priority: .high, status: .todo, dueDate: Date()),
            AppTask(title: "Update tool inventory", description: "Weekly check", priority: .low, status: .done, completedAt: Date()),
        ]
        save()
    }
}

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case overdue = "Overdue"
    case done = "Done"
}

// MARK: - MaintenanceViewModel
class MaintenanceViewModel: ObservableObject {
    @Published var records: [MaintenanceRecord] = []
    private let key = "maintenance_data"

    init() { load() }

    func add(_ rec: MaintenanceRecord) { records.append(rec); save() }
    func update(_ rec: MaintenanceRecord) {
        if let idx = records.firstIndex(where: { $0.id == rec.id }) { records[idx] = rec; save() }
    }
    func delete(_ rec: MaintenanceRecord) { records.removeAll { $0.id == rec.id }; save() }

    func records(for toolId: UUID) -> [MaintenanceRecord] {
        records.filter { $0.toolId == toolId }.sorted { $0.date > $1.date }
    }

    func upcomingDue() -> [MaintenanceRecord] {
        records.filter { rec in
            guard let due = rec.nextDueDate else { return false }
            return due <= Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MaintenanceRecord].self, from: data) else { return }
        records = decoded
    }
}
