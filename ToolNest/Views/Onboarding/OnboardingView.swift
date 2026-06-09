import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var page = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingPage1().tag(0)
                OnboardingPage2().tag(1)
                OnboardingPage3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

            // Bottom navigation
            VStack {
                Spacer()
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(page == i ? Color.accentYellow : Color.divider)
                                .frame(width: page == i ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        Button("Skip") {
                            withAnimation { hasCompletedOnboarding = true }
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button(page == 2 ? "Get Started" : "Next") {
                            if page == 2 {
                                withAnimation { hasCompletedOnboarding = true }
                            } else {
                                withAnimation { page += 1 }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - Page 1: Understand the Problem (tap animation)
struct OnboardingPage1: View {
    @State private var tapped = false
    @State private var burst = false
    @State private var burstParticles: [BurstParticle] = []
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(Color.statusError.opacity(0.1))
                    .frame(width: tapped ? 220 : 160, height: tapped ? 220 : 160)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: tapped)

                // Burst particles
                ForEach(burstParticles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .offset(x: burst ? p.targetX : 0, y: burst ? p.targetY : 0)
                        .opacity(burst ? 0 : 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: burst)
                }

                // Tool icons floating
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        ToolIconBubble(icon: "wrench.fill", color: .accentYellow, offset: isAnimating ? -4 : 4)
                        ToolIconBubble(icon: "hammer.fill", color: .accentOrange, offset: isAnimating ? 4 : -4)
                    }
                    HStack(spacing: 20) {
                        ToolIconBubble(icon: "screwdriver.fill", color: .accentBlue, offset: isAnimating ? 6 : -2)
                        ToolIconBubble(icon: "questionmark.circle.fill", color: .statusError, offset: isAnimating ? -2 : 6)
                    }
                }

                // Tap target
                Button {
                    triggerBurst()
                } label: {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: 180, height: 180)
                }
            }
            .frame(height: 280)

            Spacer().frame(height: 40)

            // Text content
            VStack(spacing: 16) {
                Text("Understand the Problem")
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Tools get lost. Nobody knows who has the drill.\nConsumables run out without warning.\nBroken tools go unnoticed.")
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Tap the tools above")
                    .font(.caption)
                    .foregroundColor(.accentYellow)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { isAnimating = true }
        }
        .onDisappear { isAnimating = false }
    }

    private func triggerBurst() {
        burstParticles = (0..<16).map { i in
            let angle = Double(i) / 16 * .pi * 2
            return BurstParticle(
                targetX: cos(angle) * CGFloat.random(in: 60...100),
                targetY: sin(angle) * CGFloat.random(in: 60...100),
                color: [Color.accentYellow, Color.accentOrange, Color.accentBlue].randomElement()!,
                size: CGFloat.random(in: 4...10)
            )
        }
        tapped = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { burst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            burst = false
            burstParticles = []
            withAnimation { tapped = false }
        }
    }
}

struct ToolIconBubble: View {
    let icon: String
    let color: Color
    let offset: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.18)).frame(width: 56, height: 56)
            Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundColor(color)
        }
        .offset(y: offset)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: offset)
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    let targetX: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
}

// MARK: - Page 2: Track Everything (drag gesture)
struct OnboardingPage2: View {
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var snapX: CGFloat = 0
    private let slots: [(name: String, icon: String, x: CGFloat)] = [
        ("Warehouse", "building.2.fill", -90),
        ("Site B", "hammer.circle.fill", 0),
        ("Workshop", "wrench.circle.fill", 90)
    ]
    @State private var assignedSlot: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Slot targets
                HStack(spacing: 16) {
                    ForEach(slots.indices, id: \.self) { i in
                        let slot = slots[i]
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(assignedSlot == i ? Color.accentYellow.opacity(0.2) : Color.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(assignedSlot == i ? Color.accentYellow : Color.divider, lineWidth: 1.5)
                                    )
                                    .frame(width: 80, height: 80)

                                Image(systemName: slot.icon)
                                    .font(.system(size: 26))
                                    .foregroundColor(assignedSlot == i ? .accentYellow : .textInactive)
                            }
                            Text(slot.name)
                                .font(.caption)
                                .foregroundColor(assignedSlot == i ? .accentYellow : .textSecondary)
                        }
                    }
                }
                .padding(.top, 120)

                // Draggable tool card
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentYellow)
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.accentYellow.opacity(0.5), radius: isDragging ? 16 : 8)
                        Image(systemName: "drill.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.bgPrimary)
                    }
                    Text("Drill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                .offset(x: dragOffset.width, y: dragOffset.height)
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            isDragging = true
                            dragOffset = val.translation
                        }
                        .onEnded { val in
                            isDragging = false
                            // Snap to nearest slot if close enough
                            let targetY: CGFloat = 120
                            if val.translation.height > 60 {
                                for i in slots.indices {
                                    if abs(val.translation.width - slots[i].x) < 60 {
                                        assignedSlot = i
                                        break
                                    }
                                }
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                )
            }
            .frame(height: 260)

            Spacer().frame(height: 32)

            VStack(spacing: 16) {
                Text("Track Everything")
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Drag the tool to assign it to a location.\nKnow where everything is at all times.")
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                if let s = assignedSlot {
                    Text("✓ Assigned to \(slots[s].name)!")
                        .font(.headlineSmall)
                        .foregroundColor(.statusGood)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: assignedSlot)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 3: Get Better Results (scroll-driven animation)
struct OnboardingPage3: View {
    @State private var progress: CGFloat = 0
    @State private var animating = false
    private let steps = ["Add tools", "Assign workers", "Track status", "Get reports"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated progress visualization
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.divider, lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animating ? 0.82 : 0)
                    .stroke(
                        AngularGradient(colors: [Color.accentYellow, Color.accentOrange], center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5).delay(0.3), value: animating)

                VStack(spacing: 2) {
                    Text("82%")
                        .font(.displayMedium)
                        .foregroundColor(.accentYellow)
                    Text("Efficiency")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer().frame(height: 32)

            // Step checklist
            VStack(spacing: 12) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(animating && i < 3 ? Color.statusGood : Color.cardBg)
                                .frame(width: 28, height: 28)
                            if animating && i < 3 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(i+1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textInactive)
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(i) * 0.15), value: animating)

                        Text(steps[i])
                            .font(.bodyLarge)
                            .foregroundColor(animating && i < 3 ? .textPrimary : .textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer().frame(height: 32)

            VStack(spacing: 16) {
                Text("Get Better Results")
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Use clear checks, reports and reminders.\nYour repair team works smarter, not harder.")
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear { animating = true }
        .onDisappear { animating = false }
    }
}
