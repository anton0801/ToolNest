import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @EnvironmentObject var consumableVM: ConsumableViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var maintenanceVM: MaintenanceViewModel
    @State private var showQuickCheck = false
    @State private var showAddTask = false
    @State private var animateStats = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tool Nest")
                                .font(.displaySmall)
                                .foregroundColor(.textPrimary)
                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        ZStack {
                            Circle().fill(Color.accentOrange.opacity(0.18)).frame(width: 44, height: 44)
                            Image(systemName: "bell.fill")
                                .foregroundColor(.accentOrange)
                                .font(.system(size: 18))
                            if !taskVM.overdueTasks.isEmpty {
                                Circle().fill(Color.statusError).frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Status summary grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Available", value: "\(toolVM.availableCount)", icon: "checkmark.circle.fill", color: .statusGood)
                            .scaleEffect(animateStats ? 1.0 : 0.8)
                            .opacity(animateStats ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.0), value: animateStats)

                        StatCard(title: "In Use", value: "\(toolVM.inUseCount)", icon: "wrench.fill", color: .statusActive)
                            .scaleEffect(animateStats ? 1.0 : 0.8)
                            .opacity(animateStats ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: animateStats)

                        StatCard(title: "Broken", value: "\(toolVM.brokenCount)", icon: "exclamationmark.triangle.fill", color: .statusError)
                            .scaleEffect(animateStats ? 1.0 : 0.8)
                            .opacity(animateStats ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: animateStats)

                        StatCard(title: "Low Stock", value: "\(consumableVM.lowStockItems.count)", icon: "exclamationmark.circle.fill", color: .statusWarning)
                            .scaleEffect(animateStats ? 1.0 : 0.8)
                            .opacity(animateStats ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15), value: animateStats)
                    }
                    .padding(.horizontal, 20)

                    // Warnings section
                    if !consumableVM.lowStockItems.isEmpty || !taskVM.overdueTasks.isEmpty || toolVM.brokenCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "⚠️ Warnings")

                            if toolVM.brokenCount > 0 {
                                WarningRow(icon: "exclamationmark.triangle.fill", color: .statusError,
                                           title: "\(toolVM.brokenCount) tool(s) broken",
                                           subtitle: "Requires attention or repair")
                            }
                            ForEach(consumableVM.lowStockItems.prefix(3)) { item in
                                WarningRow(icon: "shippingbox.fill", color: .statusWarning,
                                           title: "\(item.name) low stock",
                                           subtitle: "\(Int(item.quantity)) \(item.unit.rawValue) remaining (min: \(Int(item.minQuantity)))")
                            }
                            ForEach(taskVM.overdueTasks.prefix(2)) { task in
                                WarningRow(icon: "clock.badge.exclamationmark.fill", color: .accentOrange,
                                           title: "Overdue: \(task.title)",
                                           subtitle: task.dueDate.map { "Due \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "")
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Today's actions
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Today's Tasks")

                        if taskVM.todayTasks.isEmpty {
                            TNCard {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.statusGood)
                                    Text("All caught up for today!")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        } else {
                            ForEach(taskVM.todayTasks.prefix(3)) { task in
                                TodayTaskRow(task: task)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Maintenance due
                    let dueMaintenance = maintenanceVM.upcomingDue()
                    if !dueMaintenance.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Maintenance Due")
                            ForEach(dueMaintenance.prefix(3)) { rec in
                                TNCard {
                                    HStack {
                                        Image(systemName: "gear.circle.fill")
                                            .foregroundColor(.accentOrange)
                                            .font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rec.description)
                                                .font(.headlineSmall)
                                                .foregroundColor(.textPrimary)
                                            if let due = rec.nextDueDate {
                                                Text("Due: \(due.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.accentOrange)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Quick actions
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Quick Actions")
                        HStack(spacing: 12) {
                            Button {
                                showQuickCheck = true
                            } label: {
                                QuickActionButton(icon: "checkmark.shield.fill", label: "Quick Check", color: .accentBlue)
                            }
                            NavigationLink(destination: ReportsView()) {
                                QuickActionButton(icon: "chart.bar.fill", label: "Open Report", color: .accentOrange)
                            }
                            Button {
                                showAddTask = true
                            } label: {
                                QuickActionButton(icon: "plus.circle.fill", label: "Add Task", color: .accentYellow)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Tool Health")
                        TNCard {
                            VStack(spacing: 12) {
                                let total = toolVM.tools.count
                                let good = toolVM.availableCount + toolVM.inUseCount
                                let ratio = total > 0 ? CGFloat(good) / CGFloat(total) : 0

                                HStack {
                                    Text("Overall condition")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("\(Int(ratio * 100))%")
                                        .font(.headlineSmall)
                                        .foregroundColor(ratio > 0.7 ? .statusGood : ratio > 0.4 ? .statusWarning : .statusError)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.divider).frame(height: 8)
                                        Capsule()
                                            .fill(LinearGradient(colors: [Color.statusGood, Color.accentYellow], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * ratio, height: 8)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateStats)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .padding(.top, 16)
            }
            .navigationBarHidden(true)
            .background(Color.bgPrimary)
        }
        .onAppear { withAnimation { animateStats = true } }
        .sheet(isPresented: $showQuickCheck) { QuickCheckView() }
        .sheet(isPresented: $showAddTask) { AddTaskView() }
    }
}

struct WarningRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headlineSmall).foregroundColor(.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundColor(.textSecondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

struct TodayTaskRow: View {
    let task: AppTask
    @EnvironmentObject var taskVM: TaskViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                taskVM.markDone(task)
            } label: {
                ZStack {
                    Circle().stroke(task.priority.color, lineWidth: 2).frame(width: 24, height: 24)
                    if task.status == .done {
                        Circle().fill(task.priority.color).frame(width: 16, height: 16)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.bodyLarge).foregroundColor(.textPrimary)
                if !task.description.isEmpty {
                    Text(task.description).font(.caption).foregroundColor(.textSecondary).lineLimit(1)
                }
            }
            Spacer()
            StatusPill(text: task.priority.rawValue, color: task.priority.color)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text).font(.label).foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.18)))
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.15)).frame(width: 52, height: 52)
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            }
            Text(label).font(.label).foregroundColor(.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Check View
struct QuickCheckView: View {
    @EnvironmentObject var toolVM: ToolViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var checkedIds: Set<UUID> = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Mark tools you can confirm are present and in good condition.")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()

                    ForEach(toolVM.tools) { tool in
                        HStack(spacing: 14) {
                            Button {
                                if checkedIds.contains(tool.id) {
                                    checkedIds.remove(tool.id)
                                } else {
                                    checkedIds.insert(tool.id)
                                }
                            } label: {
                                ZStack {
                                    Circle().stroke(checkedIds.contains(tool.id) ? Color.statusGood : Color.divider, lineWidth: 2).frame(width: 28, height: 28)
                                    if checkedIds.contains(tool.id) {
                                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.statusGood)
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.name).font(.headlineSmall).foregroundColor(.textPrimary)
                                Text(tool.category).font(.caption).foregroundColor(.textSecondary)
                            }
                            Spacer()
                            StatusBadge(status: tool.status)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }

                    Button {
                        // Update checked tools to confirmed available
                        for id in checkedIds {
                            toolVM.updateStatus(toolId: id, status: .available)
                        }
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Text("Confirm Check (\(checkedIds.count) tools)")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 8)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Quick Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.accentYellow)
                }
            }
        }
    }
}
