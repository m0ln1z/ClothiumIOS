import SwiftUI

@main
struct ClothiumApp: App {
    @State private var route: Route = .welcome
    @State private var authenticatedUser: AuthUser?
    @State private var needsOnboarding: Bool = false

    enum Route { case welcome, auth, onboarding, home }

    var body: some Scene {
        WindowGroup {
            // Force light appearance for consistent minimalist look
            contentView()
                .preferredColorScheme(.light)
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
            Group {
                switch route {
                case .welcome:
                    WelcomeView { route = .auth }
                case .auth:
                    AuthView { user in
                        authenticatedUser = user
                        Task {
                            let completed = (try? await OnboardingService.shared.isOnboardingCompleted(userId: user.id)) ?? false
                            needsOnboarding = !completed
                            route = needsOnboarding ? .onboarding : .home
                        }
                    }
                case .onboarding:
                    if let user = authenticatedUser {
                        OnboardingView(user: user) {
                            needsOnboarding = false
                            route = .home
                        }
                    }
                case .home:
                    if let user = authenticatedUser {
                        HomeView(user: user)
                    } else {
                        WelcomeView { route = .auth }
                    }
                }
            }
    }
}


