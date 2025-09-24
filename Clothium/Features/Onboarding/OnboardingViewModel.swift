import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var options: [StyleOption] = StyleOption.presets
    @Published var selected: Set<StyleOption> = []
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var isCompleted: Bool = false

    private let service: OnboardingServicing
    private let user: AuthUser

    init(user: AuthUser, service: OnboardingServicing? = nil) {
        self.user = user
        self.service = service ?? OnboardingService.shared
    }

    func load() async {
        do {
            isCompleted = try await service.isOnboardingCompleted(userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ option: StyleOption) {
        if selected.contains(option) { selected.remove(option) } else { selected.insert(option) }
    }

    func submit() async {
        guard !selected.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            let ids = selected.map { $0.id }
            try await service.submitOnboarding(userId: user.id, selectedStyleIds: ids)
            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}


