import SwiftUI

@main
struct AttendyApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(.dark)

                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var taglineOpacity: Double = 0
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: "#101010").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Animated logo mark
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(hex: "#5E81AC").opacity(0),
                                    Color(hex: "#5E81AC"),
                                    Color(hex: "#8B7EB8"),
                                    Color(hex: "#7BA88E"),
                                    Color(hex: "#BF916E"),
                                    Color(hex: "#5E81AC").opacity(0)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(ringRotation))
                        .scaleEffect(ringScale)

                    // Inner icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Color(hex: "#5E81AC"))
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // App name
                HStack(spacing: 0) {
                    Text("A")
                        .font(.system(size: 38, weight: .black, design: .serif))
                        .foregroundStyle(Color(hex: "#5E81AC"))
                    Text("ttendy")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "#E0E0E0"))
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                // Tagline
                Text("Track. Attend. Succeed.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9A9A9A"))
                    .opacity(taglineOpacity)

                Spacer()

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color(hex: "#5E81AC"))
                            .frame(width: 6, height: 6)
                            .offset(y: dotOffset(for: index))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Logo entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Ring spin
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                ringScale = 1.0
            }

            // Tagline fade-in
            withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
                taglineOpacity = 1.0
            }

            // Bounce dots
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                dotOffset = -6
            }
        }
    }

    private func dotOffset(for index: Int) -> CGFloat {
        let phase = dotOffset * (index == 1 ? -1 : 1) * (index == 0 ? 0.7 : index == 2 ? 0.5 : 1.0)
        return phase
    }
}
