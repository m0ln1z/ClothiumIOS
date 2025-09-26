import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case styles, sizes, height, colors, budget, selfie, summary
    }

    enum ClothingSize: String, CaseIterable, Identifiable {
        case xs = "XS", s = "S", m = "M", l = "L", xl = "XL", xxl = "XXL"
        var id: String { rawValue }
        var title: String { rawValue }
    }

    enum ColorTag: String, CaseIterable, Identifiable {
        case black, white, gray, blue, green, red, beige, brown
        var id: String { rawValue }
        var title: String {
            switch self {
            case .black: return "Чёрный"
            case .white: return "Белый"
            case .gray: return "Серый"
            case .blue: return "Синий"
            case .green: return "Зелёный"
            case .red: return "Красный"
            case .beige: return "Бежевый"
            case .brown: return "Коричневый"
            }
        }
        var color: Color {
            switch self {
            case .black: return .black
            case .white: return .white
            case .gray: return .gray
            case .blue: return .blue
            case .green: return .green
            case .red: return .red
            case .beige: return Color(red: 0.94, green: 0.89, blue: 0.80)
            case .brown: return Color(red: 0.42, green: 0.27, blue: 0.15)
            }
        }
    }

    enum Budget: String, CaseIterable, Identifiable {
        case low, medium, high
        var id: String { rawValue }
        var title: String {
            switch self {
            case .low: return "Низкий"
            case .medium: return "Средний"
            case .high: return "Высокий"
            }
        }
    }

    enum Frequency: String, CaseIterable, Identifiable {
        case monthly, quarterly, halfYearly
        var id: String { rawValue }
        var title: String {
            switch self {
            case .monthly: return "Раз в месяц"
            case .quarterly: return "Раз в квартал"
            case .halfYearly: return "Раз в полгода"
            }
        }
    }

    // Шаги
    @Published var step: Step = .styles

    // Шаг 1: стили
    @Published var options: [StyleOption] = StyleOption.presets
    @Published var selected: Set<StyleOption> = []

    // Шаг 2: размеры
    @Published var topSize: ClothingSize?
    @Published var bottomSize: ClothingSize?
    @Published var shoeSize: Int? // EU

    // Шаг 3: рост
    @Published var height: Int? = 170

    // Шаг 4: цвета
    @Published var preferredColors: Set<ColorTag> = []

    // Шаг 5: бюджет и частота
    @Published var budget: Budget?
    @Published var frequency: Frequency?

    // Шаг 6: селфи
    @Published var selfieImage: UIImage?

    // Служебное
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

    // MARK: - Step titles
    var stepTitle: String {
        switch step {
        case .styles: return "Ваш стиль"
        case .sizes: return "Ваши размеры"
        case .height: return "Ваш рост"
        case .colors: return "Любимые цвета"
        case .budget: return "Бюджет и частота"
        case .selfie: return "Селфи для профиля"
        case .summary: return "Ваш профиль"
        }
    }

    var stepSubtitle: String {
        switch step {
        case .styles: return "Выберите один вариант или больше"
        case .sizes: return "Поможет предлагать подходящий крой"
        case .height: return "Укажите рост, чтобы точнее подобрать посадку"
        case .colors: return "Выберите цвета, которые вам нравятся"
        case .budget: return "Чтобы рекомендации были уместными"
        case .selfie: return "Сделайте фото лица — это поможет персонализации"
        case .summary: return "Проверьте параметры перед завершением"
        }
    }

    // MARK: - Validation
    var canGoNext: Bool {
        switch step {
        case .styles:
            return !selected.isEmpty
        case .sizes, .height, .colors, .budget, .selfie:
            return true // можно пропустить/идти дальше
        case .summary:
            return true
        }
    }

    var canSkip: Bool {
        switch step {
        case .styles, .summary:
            return false
        default:
            return true
        }
    }

    // MARK: - Step control
    func next() {
        guard let nextStep = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { step = nextStep }
    }

    func back() {
        guard let prevStep = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { step = prevStep }
    }

    func skip() {
        guard canSkip else { return }
        next()
    }

    func toggle(_ option: StyleOption) {
        if selected.contains(option) { selected.remove(option) } else { selected.insert(option) }
    }

    func toggleColor(_ tag: ColorTag) {
        if preferredColors.contains(tag) { preferredColors.remove(tag) } else { preferredColors.insert(tag) }
    }

    func setSelfie(image: UIImage) {
        selfieImage = image
    }

    // MARK: - Submit
    func submitAll() async {
        isSubmitting = true
        errorMessage = nil
        do {
            // 1) Отправим стили на сервер (как и раньше)
            let ids = selected.map { $0.id }
            try await service.submitOnboarding(userId: user.id, selectedStyleIds: ids)

            // 2) Сохраним локально доп. данные
            saveLocalPreferences()

            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    // MARK: - Local store
    private func saveLocalPreferences() {
        var selfiePath: String?
        if let img = selfieImage, let data = img.jpegData(compressionQuality: 0.9) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let file = url.appendingPathComponent("selfie_\(user.id).jpg")
            try? data.write(to: file, options: .atomic)
            selfiePath = file.path
        }

        let prefs = OnboardingPreferences(
            topSize: topSize?.rawValue,
            bottomSize: bottomSize?.rawValue,
            shoeSize: shoeSize,
            height: height,
            colors: preferredColors.map { $0.rawValue },
            budget: budget?.rawValue,
            frequency: frequency?.rawValue,
            selfiePath: selfiePath
        )
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: "onb_prefs_\(user.id)")
        }
    }

    struct OnboardingPreferences: Codable {
        let topSize: String?
        let bottomSize: String?
        let shoeSize: Int?
        let height: Int?
        let colors: [String]
        let budget: String?
        let frequency: String?
        let selfiePath: String?
    }

    // MARK: - Helpers
    var shoeSizes: [Int] { Array(36...46) }
    var heightRange: [Int] { Array(150...210) }
}
