import SwiftUI
import Foundation

// MARK: - Tool Model
enum ToolStatus: String, Codable, CaseIterable {
    case available = "Available"
    case inUse = "In Use"
    case broken = "Broken"
    case lost = "Lost"
    case maintenance = "Maintenance"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .available: return .statusGood
        case .inUse: return .statusActive
        case .broken: return .statusError
        case .lost: return Color(hex: "#F97316")
        case .maintenance: return .statusWarning
        }
    }

    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .inUse: return "wrench.fill"
        case .broken: return "exclamationmark.triangle.fill"
        case .lost: return "questionmark.circle.fill"
        case .maintenance: return "gear.circle.fill"
        }
    }
}

enum ToolCondition: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: Color {
        switch self {
        case .excellent: return .statusGood
        case .good: return Color(hex: "#86EFAC")
        case .fair: return .statusWarning
        case .poor: return .statusError
        }
    }
}

struct Tool: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var status: ToolStatus
    var condition: ToolCondition
    var locationId: UUID?
    var workerId: UUID?
    var serialNumber: String
    var notes: String
    var purchaseDate: Date?
    var lastMaintenanceDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Consumable Model
enum ConsumableUnit: String, Codable, CaseIterable {
    case pieces = "pcs"
    case kilograms = "kg"
    case liters = "L"
    case meters = "m"
    case boxes = "box"
    case rolls = "rolls"
}

struct Consumable: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var quantity: Double
    var minQuantity: Double
    var unit: ConsumableUnit
    var locationId: UUID?
    var notes: String
    var cost: Double
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var isLowStock: Bool { quantity <= minQuantity }
}

// MARK: - Location Model
struct Location: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: String
    var address: String
    var notes: String
    var createdAt: Date = Date()
}

// MARK: - Worker Model
struct Worker: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var phone: String
    var notes: String
    var isActive: Bool = true
    var createdAt: Date = Date()
}

// MARK: - Task Model
enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: Color {
        switch self {
        case .low: return .textInactive
        case .medium: return .statusActive
        case .high: return .statusWarning
        case .urgent: return .statusError
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
    case overdue = "Overdue"
}

struct AppTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var priority: TaskPriority
    var status: TaskStatus
    var dueDate: Date?
    var toolId: UUID?
    var workerId: UUID?
    var createdAt: Date = Date()
    var completedAt: Date?

    var isOverdue: Bool {
        guard let due = dueDate, status != .done else { return false }
        return due < Date()
    }

    var isToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
}

// MARK: - Maintenance Model
enum MaintenanceType: String, Codable, CaseIterable {
    case inspection = "Inspection"
    case repair = "Repair"
    case calibration = "Calibration"
    case cleaning = "Cleaning"
    case replacement = "Replacement"
}

struct MaintenanceRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var toolId: UUID
    var type: MaintenanceType
    var description: String
    var performedBy: String
    var cost: Double
    var date: Date
    var nextDueDate: Date?
    var notes: String
    var createdAt: Date = Date()
}

// MARK: - Tool Categories
let toolCategories = [
    "Power Tools", "Hand Tools", "Measuring", "Safety", "Cutting",
    "Drilling", "Fastening", "Lifting", "Electrical", "Plumbing", "Other"
]

let consumableCategories = [
    "Fasteners", "Adhesives", "Abrasives", "Paint", "Lubricants",
    "Safety", "Electrical", "Plumbing", "Cleaning", "Other"
]
