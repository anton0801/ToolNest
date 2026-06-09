import SwiftUI

struct ConsumablesView: View {
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @State private var showAdd = false
    @State private var selected: Consumable? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Consumables")
                                .font(.displaySmall)
                                .foregroundColor(.textPrimary)
                            Text("\(consumableVM.lowStockItems.count) low stock items")
                                .font(.caption)
                                .foregroundColor(consumableVM.lowStockItems.isEmpty ? .textSecondary : .statusWarning)
                        }
                        Spacer()
                        Button { showAdd = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentYellow)
                        }
                    }
                    TNTextField(placeholder: "Search consumables...", text: $consumableVM.searchText, icon: "magnifyingglass")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if consumableVM.filtered.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "shippingbox", title: "No consumables",
                                   subtitle: "Track screws, paint, glue and other consumable items.")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(consumableVM.filtered) { item in
                                ConsumableCard(item: item)
                                    .onTapGesture { selected = item }
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
        .sheet(isPresented: $showAdd) { AddConsumableView() }
        .sheet(item: $selected) { item in ConsumableDetailView(item: item) }
    }
}

struct ConsumableCard: View {
    let item: Consumable
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var locationVM: LocationViewModel

    var stockRatio: CGFloat {
        item.minQuantity > 0 ? min(CGFloat(item.quantity / item.minQuantity), 2) / 2 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.isLowStock ? Color.statusWarning.opacity(0.15) : Color.accentBlue.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: item.isLowStock ? "exclamationmark.triangle.fill" : "shippingbox.fill")
                        .font(.system(size: 20))
                        .foregroundColor(item.isLowStock ? .statusWarning : .accentBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name).font(.headlineLarge).foregroundColor(.textPrimary)
                        Spacer()
                        if item.isLowStock {
                            Text("LOW STOCK").font(.label).foregroundColor(.statusWarning)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Color.statusWarning.opacity(0.18)))
                        }
                    }
                    Text(item.category).font(.caption).foregroundColor(.accentBlue)
                    HStack(spacing: 4) {
                        Text("\(item.quantity, specifier: "%.0f")")
                            .font(.headlineLarge).foregroundColor(item.isLowStock ? .statusWarning : .textPrimary)
                        Text(item.unit.rawValue).font(.bodySmall).foregroundColor(.textSecondary)
                        Text("/ min \(item.minQuantity, specifier: "%.0f")").font(.caption).foregroundColor(.textInactive)
                    }
                }
            }

            // Stock bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.divider).frame(height: 4)
                    Capsule()
                        .fill(item.isLowStock ? Color.statusWarning : Color.statusGood)
                        .frame(width: geo.size.width * stockRatio, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.top, 10)

            // Quick adjust
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        consumableVM.adjustQuantity(id: item.id, delta: -1)
                    } label: {
                        Image(systemName: "minus").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textSecondary).frame(width: 36, height: 28)
                    }
                    Text("\(Int(item.quantity))").font(.headlineSmall).foregroundColor(.textPrimary).frame(width: 40)
                    Button {
                        consumableVM.adjustQuantity(id: item.id, delta: 1)
                    } label: {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textSecondary).frame(width: 36, height: 28)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.divider, lineWidth: 1))
            }
            .padding(.top, 8)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(item.isLowStock ? Color.statusWarning.opacity(0.4) : Color.divider, lineWidth: 1))
    }
}

// MARK: - Add Consumable
struct AddConsumableView: View {
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name = ""
    @State private var category = consumableCategories[0]
    @State private var quantity = ""
    @State private var minQuantity = ""
    @State private var unit = ConsumableUnit.pieces
    @State private var selectedLocation: UUID? = nil
    @State private var cost = ""
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TNTextField(placeholder: "Item Name *", text: $name, icon: "shippingbox.fill")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.caption).foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(consumableCategories, id: \.self) { cat in
                                    Button(cat) { category = cat }
                                        .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Capsule().fill(category == cat ? Color.accentYellow.opacity(0.2) : Color.cardBg))
                                        .foregroundColor(category == cat ? .accentYellow : .textSecondary)
                                        .overlay(Capsule().stroke(category == cat ? Color.accentYellow.opacity(0.4) : Color.divider, lineWidth: 1))
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        TNTextField(placeholder: "Quantity *", text: $quantity, icon: "number")
                        TNTextField(placeholder: "Min qty", text: $minQuantity)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unit").font(.caption).foregroundColor(.textSecondary)
                        Picker("Unit", selection: $unit) {
                            ForEach(ConsumableUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Picker("Location", selection: $selectedLocation) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(locationVM.locations) { l in Text(l.name).tag(Optional(l.id)) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                    TNTextField(placeholder: "Unit Cost", text: $cost, icon: "dollarsign.circle")
                    TNTextField(placeholder: "Notes", text: $notes, icon: "note.text")

                    if showError { Text("Name and quantity are required").font(.caption).foregroundColor(.statusError) }

                    Button("Save Item") {
                        guard !name.isEmpty, let qty = Double(quantity) else { showError = true; return }
                        let item = Consumable(
                            name: name, category: category,
                            quantity: qty, minQuantity: Double(minQuantity) ?? 0,
                            unit: unit, locationId: selectedLocation,
                            notes: notes, cost: Double(cost) ?? 0
                        )
                        consumableVM.add(item)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20).padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Consumable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Consumable Detail
struct ConsumableDetailView: View {
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var locationVM: LocationViewModel
    @Environment(\.presentationMode) var dismiss

    var item: Consumable
    @State private var adjustAmount = ""
    @State private var showEdit = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero card
                    TNCard {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name).font(.displaySmall).foregroundColor(.textPrimary)
                                    Text(item.category).font(.caption).foregroundColor(.accentBlue)
                                }
                                Spacer()
                                if item.isLowStock {
                                    Text("⚠️ LOW").font(.headlineSmall).foregroundColor(.statusWarning)
                                        .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.statusWarning.opacity(0.15)))
                                }
                            }
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Current").font(.caption).foregroundColor(.textSecondary)
                                    Text("\(item.quantity, specifier: "%.1f") \(item.unit.rawValue)")
                                        .font(.displayMedium).foregroundColor(item.isLowStock ? .statusWarning : .accentYellow)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Minimum").font(.caption).foregroundColor(.textSecondary)
                                    Text("\(item.minQuantity, specifier: "%.0f") \(item.unit.rawValue)")
                                        .font(.displaySmall).foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Quick adjust
                    TNCard {
                        VStack(spacing: 12) {
                            Text("Adjust Quantity").font(.headlineLarge).foregroundColor(.textPrimary)
                            HStack(spacing: 12) {
                                Button("-10") { consumableVM.adjustQuantity(id: item.id, delta: -10) }
                                    .buttonStyle(SecondaryButtonStyle())
                                Button("-1") { consumableVM.adjustQuantity(id: item.id, delta: -1) }
                                    .buttonStyle(SecondaryButtonStyle())
                                Button("+1") { consumableVM.adjustQuantity(id: item.id, delta: 1) }
                                    .buttonStyle(SecondaryButtonStyle())
                                Button("+10") { consumableVM.adjustQuantity(id: item.id, delta: 10) }
                                    .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Info
                    TNCard {
                        VStack(spacing: 14) {
                            DetailRow(label: "Location", value: locationVM.name(for: item.locationId))
                            Divider().background(Color.divider)
                            DetailRow(label: "Unit Cost", value: item.cost > 0 ? "$\(String(format: "%.2f", item.cost))" : "—")
                            Divider().background(Color.divider)
                            DetailRow(label: "Total Value", value: item.cost > 0 ? "$\(String(format: "%.2f", item.cost * item.quantity))" : "—",
                                      valueColor: .accentYellow)
                            if !item.notes.isEmpty {
                                Divider().background(Color.divider)
                                DetailRow(label: "Notes", value: item.notes)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button("Delete Item") {
                        consumableVM.delete(item)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(DangerButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showEdit = true }.foregroundColor(.accentYellow)
                }
            }
        }
        .sheet(isPresented: $showEdit) { AddConsumableView() }
    }
}
