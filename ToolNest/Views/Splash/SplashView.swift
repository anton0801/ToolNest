import SwiftUI

struct SplashView: View {
    @Binding var isVisible: Bool
    @State private var animating = false
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var bgShift: CGFloat = 0
    @State private var gearRotation: Double = 0
    @State private var gear2Rotation: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    let particles: [ParticleData] = (0..<12).map { i in
        ParticleData(
            x: CGFloat.random(in: 0.1...0.9),
            y: CGFloat.random(in: 0.1...0.9),
            size: CGFloat.random(in: 4...10),
            delay: Double(i) * 0.08
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Animated gradient background
                LinearGradient(
                    colors: [Color.bgPrimary, Color(hex: "#0D1520"), Color.bgDeep],
                    startPoint: animating ? .topLeading : .bottomTrailing,
                    endPoint: animating ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animating)

                // Subtle grid pattern
                GeometryReader { _ in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        let spacing: CGFloat = 40
                        var x: CGFloat = 0
                        while x <= w {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: h))
                            x += spacing
                        }
                        var y: CGFloat = 0
                        while y <= h {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: w, y: y))
                            y += spacing
                        }
                    }
                    .stroke(Color.accentYellow.opacity(0.04), lineWidth: 0.5)
                }
                .ignoresSafeArea()

                // Layer 2: Floating particles
                ForEach(particles.indices, id: \.self) { i in
                    let p = particles[i]
                    Circle()
                        .fill(i % 3 == 0 ? Color.accentYellow : i % 3 == 1 ? Color.accentOrange : Color.accentBlue)
                        .frame(width: p.size, height: p.size)
                        .position(x: geo.size.width * p.x, y: geo.size.height * p.y)
                        .opacity(particleOpacity * (0.5 + Double(p.size) / 20))
                        .offset(y: animating ? -8 : 8)
                        .animation(
                            .easeInOut(duration: 2 + Double(i % 3))
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                            value: animating
                        )
                }

                // Layer 2: Large gears
                VStack { Spacer() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Group {
                        // Big gear behind-left
                        GearShape(teeth: 12)
                            .stroke(Color.accentYellow.opacity(0.12), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(gearRotation))
                            .offset(x: -geo.size.width * 0.35, y: geo.size.height * 0.25)

                        // Medium gear right
                        GearShape(teeth: 8)
                            .stroke(Color.accentOrange.opacity(0.1), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-gear2Rotation * 1.5))
                            .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.2)

                        // Small gear
                        GearShape(teeth: 6)
                            .stroke(Color.accentBlue.opacity(0.12), lineWidth: 1.5)
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(gear2Rotation * 2))
                            .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.3)
                    }
                )

                // Layer 3: Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Icon group
                    ZStack {
                        Circle()
                            .fill(Color.accentYellow.opacity(0.08))
                            .frame(width: 140, height: 140)

                        Circle()
                            .fill(Color.accentYellow.opacity(0.12))
                            .frame(width: 110, height: 110)

                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentYellow, Color.accentOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 84, height: 84)
                                .shadow(color: Color.accentYellow.opacity(0.5), radius: 20, x: 0, y: 8)

                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(.bgPrimary)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Spacer().frame(height: 32)

                    // App name
                    VStack(spacing: 8) {
                        Text("TOOL NEST")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .tracking(4)

                        Text("Smart repair assistant")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.accentYellow)
                            .tracking(1)
                            .opacity(subtitleOpacity)
                    }
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                    Spacer()

                    // Loading bar
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            ForEach(0..<5) { i in
                                Capsule()
                                    .fill(animating ? Color.accentYellow : Color.divider)
                                    .frame(height: 3)
                                    .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.1), value: animating)
                            }
                        }
                        .frame(width: 120)

                        Text("Loading your workspace...")
                            .font(.caption)
                            .foregroundColor(.textInactive)
                    }
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 32)
            }
            .scaleEffect(exitScale)
            .opacity(exitOpacity)
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .onDisappear { cleanupAnimations() }
    }

    private func startAnimations() {
        animating = true
        // Phase 1: background (0-0.6s)
        withAnimation(.easeIn(duration: 0.5)) { particleOpacity = 1 }
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            gearRotation = 360
            gear2Rotation = 360
        }

        // Phase 2: logo (0.6-1.4s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Phase 3: title (1.4-2.2s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.6)) {
            subtitleOpacity = 1.0
        }

        // Phase 4: exit (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard isVisible else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                exitScale = 1.08
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isVisible = false
            }
        }
    }

    private func cleanupAnimations() {
        animating = false
        logoScale = 0.3
        logoOpacity = 0
        titleOffset = 30
        titleOpacity = 0
        subtitleOpacity = 0
        particleOpacity = 0
        gearRotation = 0
        gear2Rotation = 0
    }
}

struct ParticleData {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
}

// MARK: - Gear Shape
struct GearShape: Shape {
    let teeth: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.75
        let toothHeight = outerRadius * 0.25
        let toothWidth = .pi * 2 / Double(teeth) * 0.4

        var path = Path()
        let step = .pi * 2 / Double(teeth)

        for i in 0..<teeth {
            let angle = step * Double(i) - .pi / 2
            let mid = angle + step / 2

            let p1 = point(center: center, radius: innerRadius, angle: angle)
            let p2 = point(center: center, radius: outerRadius, angle: angle + toothWidth)
            let p3 = point(center: center, radius: outerRadius, angle: mid - toothWidth)
            let p4 = point(center: center, radius: innerRadius, angle: mid)
            let p5 = point(center: center, radius: innerRadius, angle: mid + toothWidth * 0.5)

            if i == 0 { path.move(to: p1) } else { path.addLine(to: p1) }
            path.addLine(to: p2)
            path.addLine(to: p3)
            path.addLine(to: p4)
            _ = p5
        }
        path.closeSubpath()

        // Center hole
        let holeRadius = innerRadius * 0.3
        path.addEllipse(in: CGRect(x: center.x - holeRadius, y: center.y - holeRadius,
                                   width: holeRadius * 2, height: holeRadius * 2))
        return path
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * Foundation.cos(angle), y: center.y + radius * Foundation.sin(angle))
    }
}
