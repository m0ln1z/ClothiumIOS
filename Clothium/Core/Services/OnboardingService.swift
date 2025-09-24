import Foundation

struct StyleOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

protocol OnboardingServicing {
    func isOnboardingCompleted(userId: String) async throws -> Bool
    func submitOnboarding(userId: String, selectedStyleIds: [String]) async throws
}

final class OnboardingService: OnboardingServicing {
    static let shared = OnboardingService()
    private init() {}

    private let storageKeyPrefix = "onb_completed_"

    func isOnboardingCompleted(userId: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        let key = storageKeyPrefix + userId
        return UserDefaults.standard.bool(forKey: key)
    }

    func submitOnboarding(userId: String, selectedStyleIds: [String]) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        let key = storageKeyPrefix + userId
        UserDefaults.standard.set(true, forKey: key)
    }
}

extension StyleOption {
    static let presets: [StyleOption] = [
        .init(id: "classic", title: "Строгий", subtitle: "классика, офис, минимализм"),
        .init(id: "casual", title: "Свободный", subtitle: "ежедневный комфорт"),
        .init(id: "sport", title: "Спортивный", subtitle: "спортивный костюм, атлетический"),
        .init(id: "street", title: "Уличный", subtitle: "оверсайз, принты"),
        .init(id: "romantic", title: "Романтичный", subtitle: "нежные силуэты"),
        .init(id: "edgy", title: "Дерзкий", subtitle: "кожа, металл, акценты")
    ]
}


