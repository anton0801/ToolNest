import Foundation
import Combine

class ToolViewModel: ObservableObject {
    @Published var tools: [Tool] = []
    @Published var searchText: String = ""
    @Published var filterStatus: ToolStatus? = nil

    private let key = "tools_data"

    init() { load() }

    var filteredTools: [Tool] {
        var result = tools
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        return result
    }

    var availableCount: Int { tools.filter { $0.status == .available }.count }
    var inUseCount: Int { tools.filter { $0.status == .inUse }.count }
    var brokenCount: Int { tools.filter { $0.status == .broken }.count }
    var lostCount: Int { tools.filter { $0.status == .lost }.count }
    var maintenanceCount: Int { tools.filter { $0.status == .maintenance }.count }

    func add(_ tool: Tool) {
        tools.append(tool)
        save()
    }

    func update(_ tool: Tool) {
        if let idx = tools.firstIndex(where: { $0.id == tool.id }) {
            var updated = tool
            updated.updatedAt = Date()
            tools[idx] = updated
            save()
        }
    }

    func delete(_ tool: Tool) {
        tools.removeAll { $0.id == tool.id }
        save()
    }

    func assignWorker(toolId: UUID, workerId: UUID?) {
        if let idx = tools.firstIndex(where: { $0.id == toolId }) {
            tools[idx].workerId = workerId
            tools[idx].status = workerId != nil ? .inUse : .available
            tools[idx].updatedAt = Date()
            save()
        }
    }

    func markReturned(toolId: UUID) {
        if let idx = tools.firstIndex(where: { $0.id == toolId }) {
            tools[idx].workerId = nil
            tools[idx].status = .available
            tools[idx].updatedAt = Date()
            save()
        }
    }

    func updateStatus(toolId: UUID, status: ToolStatus) {
        if let idx = tools.firstIndex(where: { $0.id == toolId }) {
            tools[idx].status = status
            tools[idx].updatedAt = Date()
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tools) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Tool].self, from: data) else {
            loadSampleData()
            return
        }
        tools = decoded
    }

    private func loadSampleData() {
        tools = [
            Tool(name: "Bosch Drill", category: "Power Tools", status: .available, condition: .excellent, serialNumber: "BD-001", notes: "Main drill, 18V"),
            Tool(name: "Hammer 500g", category: "Hand Tools", status: .inUse, condition: .good, serialNumber: "HM-001", notes: ""),
            Tool(name: "Laser Level", category: "Measuring", status: .available, condition: .good, serialNumber: "LL-001", notes: "Green beam"),
            Tool(name: "Angle Grinder", category: "Power Tools", status: .broken, condition: .poor, serialNumber: "AG-001", notes: "Needs new disc guard"),
            Tool(name: "Measuring Tape 5m", category: "Measuring", status: .available, condition: .fair, serialNumber: "MT-001", notes: ""),
            Tool(name: "Circular Saw", category: "Power Tools", status: .maintenance, condition: .good, serialNumber: "CS-001", notes: "Blade sharpening"),
        ]
        save()
    }
}
