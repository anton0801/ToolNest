import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0: DashboardView()
                case 1: ToolsView()
                case 2: ConsumablesView()
                case 3: TasksView()
                case 4: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("wrench.and.screwdriver.fill", "Tools"),
        ("shippingbox.fill", "Stock"),
        ("checklist", "Tasks"),
        ("gearshape.fill", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentYellow.opacity(0.15))
                                    .frame(width: 48, height: 32)
                            }
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 18, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .accentYellow : .textInactive)
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                        }
                        Text(tabs[i].label)
                            .font(.label)
                            .foregroundColor(selectedTab == i ? .accentYellow : .textInactive)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.divider, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.4), radius: 16, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}
