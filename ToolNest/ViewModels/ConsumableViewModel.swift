import Foundation

class ConsumableViewModel: ObservableObject {
    @Published var consumables: [Consumable] = []
    @Published var searchText: String = ""

    private let key = "consumables_data"

    init() { load() }

    var filtered: [Consumable] {
        searchText.isEmpty ? consumables : consumables.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var lowStockItems: [Consumable] { consumables.filter { $0.isLowStock } }

    func add(_ item: Consumable) { consumables.append(item); save() }
    func update(_ item: Consumable) {
        if let idx = consumables.firstIndex(where: { $0.id == item.id }) {
            consumables[idx] = item; save()
        }
    }
    func delete(_ item: Consumable) { consumables.removeAll { $0.id == item.id }; save() }

    func adjustQuantity(id: UUID, delta: Double) {
        if let idx = consumables.firstIndex(where: { $0.id == id }) {
            consumables[idx].quantity = max(0, consumables[idx].quantity + delta)
            consumables[idx].updatedAt = Date()
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(consumables) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Consumable].self, from: data) else {
            loadSampleData(); return
        }
        consumables = decoded
    }

    private func loadSampleData() {
        consumables = [
            Consumable(name: "Wood Screws M4x50", category: "Fasteners", quantity: 120, minQuantity: 50, unit: .pieces, notes: "Zinc plated", cost: 0.05),
            Consumable(name: "Sandpaper P120", category: "Abrasives", quantity: 8, minQuantity: 10, unit: .pieces, notes: "", cost: 1.5),
            Consumable(name: "PVA Glue", category: "Adhesives", quantity: 2.5, minQuantity: 1.0, unit: .liters, notes: "General purpose", cost: 3.0),
            Consumable(name: "Safety Gloves L", category: "Safety", quantity: 3, minQuantity: 5, unit: .pieces, notes: "", cost: 4.0),
            Consumable(name: "WD-40 Spray", category: "Lubricants", quantity: 2, minQuantity: 2, unit: .pieces, notes: "", cost: 6.0),
        ]
        save()
    }
}
