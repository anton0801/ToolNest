import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var maintenanceVM: MaintenanceViewModel
    @State private var animateCharts = false
    @State private var showExportConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Reports")
                    .font(.displaySmall)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Tool status breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tool Status Overview")
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)

                    TNCard {
                        VStack(spacing: 14) {
                            let total = max(toolVM.tools.count, 1)
                            BarChartRow(label: "Available", count: toolVM.availableCount, total: total, color: .statusGood, animate: animateCharts)
                            BarChartRow(label: "In Use", count: toolVM.inUseCount, total: total, color: .statusActive, animate: animateCharts)
                            BarChartRow(label: "Broken", count: toolVM.brokenCount, total: total, color: .statusError, animate: animateCharts)
                            BarChartRow(label: "Lost", count: toolVM.lostCount, total: total, color: .accentOrange, animate: animateCharts)
                            BarChartRow(label: "Maintenance", count: toolVM.maintenanceCount, total: total, color: .statusWarning, animate: animateCharts)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Category breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tools by Category")
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)

                    TNCard {
                        let grouped = Dictionary(grouping: toolVM.tools, by: { $0.category })
                        let sorted = grouped.sorted { $0.value.count > $1.value.count }
                        VStack(spacing: 12) {
                            ForEach(sorted.prefix(6), id: \.key) { item in
                                BarChartRow(label: item.key, count: item.value.count,
                                            total: max(toolVM.tools.count, 1), color: .accentBlue, animate: animateCharts)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Tasks summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tasks Summary")
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MiniStatCard(title: "Total Tasks", value: "\(taskVM.tasks.count)", color: .accentBlue)
                        MiniStatCard(title: "Completed", value: "\(taskVM.tasks.filter{$0.status == .done}.count)", color: .statusGood)
                        MiniStatCard(title: "Overdue", value: "\(taskVM.overdueTasks.count)", color: .statusError)
                        MiniStatCard(title: "Today", value: "\(taskVM.todayTasks.count)", color: .statusWarning)
                    }
                    .padding(.horizontal, 20)
                }

                // Consumables overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Consumables Health")
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 20)

                    TNCard {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(consumableVM.consumables.count)")
                                        .font(.displayMedium).foregroundColor(.textPrimary)
                                    Text("Total Items").font(.caption).foregroundColor(.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(consumableVM.lowStockItems.count)")
                                        .font(.displayMedium)
                                        .foregroundColor(consumableVM.lowStockItems.isEmpty ? .statusGood : .statusWarning)
                                    Text("Low Stock").font(.caption).foregroundColor(.textSecondary)
                                }
                            }

                            let healthRatio = consumableVM.consumables.isEmpty ? 1.0 :
                                CGFloat(consumableVM.consumables.count - consumableVM.lowStockItems.count) / CGFloat(consumableVM.consumables.count)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.divider).frame(height: 10)
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color.statusGood, Color.accentYellow], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * (animateCharts ? healthRatio : 0), height: 10)
                                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCharts)
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Maintenance costs
                let mainCosts = maintenanceVM.records.reduce(0) { $0 + $1.cost }
                if mainCosts > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maintenance")
                            .font(.headlineLarge).foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        TNCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(maintenanceVM.records.count)").font(.displayMedium).foregroundColor(.textPrimary)
                                    Text("Records").font(.caption).foregroundColor(.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("$\(String(format: "%.0f", mainCosts))").font(.displayMedium).foregroundColor(.accentYellow)
                                    Text("Total Cost").font(.caption).foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Export
                VStack(spacing: 12) {
                    Button {
                        showExportConfirm = true
                    } label: {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.bgPrimary)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) { animateCharts = true } }
        .alert("Export Report", isPresented: $showExportConfirm) {
            Button("Export as Text") { exportAsText() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose export format for your Tool Nest report.")
        }
    }

    private func exportAsText() {
        let report = """
        TOOL NEST REPORT
        Generated: \(Date().formatted())

        TOOL INVENTORY:
        Total: \(toolVM.tools.count)
        Available: \(toolVM.availableCount)
        In Use: \(toolVM.inUseCount)
        Broken: \(toolVM.brokenCount)
        Lost: \(toolVM.lostCount)

        CONSUMABLES:
        Total Items: \(consumableVM.consumables.count)
        Low Stock: \(consumableVM.lowStockItems.count)

        TASKS:
        Total: \(taskVM.tasks.count)
        Completed: \(taskVM.tasks.filter{$0.status == .done}.count)
        Overdue: \(taskVM.overdueTasks.count)

        MAINTENANCE:
        Records: \(maintenanceVM.records.count)
        Total Cost: $\(String(format: "%.2f", maintenanceVM.records.reduce(0) { $0 + $1.cost }))
        """

        let av = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = windowScene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }
}

struct BarChartRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    let animate: Bool

    var ratio: CGFloat { CGFloat(count) / CGFloat(total) }

    var body: some View {
        HStack(spacing: 12) {
            Text(label).font(.bodySmall).foregroundColor(.textSecondary).frame(width: 90, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.divider).frame(height: 8)
                    Capsule().fill(color)
                        .frame(width: max(8, geo.size.width * (animate ? ratio : 0)), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
                }
            }
            .frame(height: 8)
            Text("\(count)").font(.headlineSmall).foregroundColor(.textPrimary).frame(width: 32, alignment: .trailing)
        }
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.displaySmall).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
}
