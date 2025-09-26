import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @StateObject private var camera = CameraManager()

    @State private var cameraAuthStatus: AVAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false

    var onFinished: () -> Void

    init(user: AuthUser, onFinished: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(user: user))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                // Верхняя панель с кнопкой "Назад"
                topBar

                // Прогресс-бар
                stepProgress

                // Заголовки
                VStack(spacing: 6) {
                    Text(viewModel.stepTitle)
                        .font(.largeTitle.bold())
                        .foregroundStyle(BrandTheme.textPrimary)
                    Text(viewModel.stepSubtitle)
                        .foregroundStyle(BrandTheme.textSecondary)
                        .font(.subheadline)
                }
                .padding(.top, 4)

                // Контент шага
                Group {
                    switch viewModel.step {
                    case .styles:
                        stylesStep
                    case .sizes:
                        sizesStep
                    case .height:
                        heightStep
                    case .colors:
                        colorsStep
                    case .budget:
                        budgetStep
                    case .selfie:
                        selfieStep
                    case .summary:
                        summaryStep
                    }
                }
                .padding(.horizontal, 16)

                // Ошибка
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }

                // Нижние кнопки управления:
                // Держим место под панель, чтобы не прыгала верстка на шаге селфи.
                controls
                    .opacity(viewModel.step == .selfie ? 0 : 1)
                    .allowsHitTesting(viewModel.step != .selfie)
            }
            // Весь контент привязываем к верху
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.isCompleted) { _, done in
            if done { onFinished() }
        }
        // Жест "свайп от левого края" для шага Назад
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 50 && abs(value.translation.height) < 40 {
                        if viewModel.step != .styles {
                            viewModel.back()
                        }
                    }
                }
        )
        // Управление жизненным циклом камеры при переходах по шагам
        .onChange(of: viewModel.step) { _, newStep in
            if newStep == .selfie {
                prepareCamera()
            } else {
                camera.stopSession()
            }
        }
        .onAppear {
            if viewModel.step == .selfie { prepareCamera() }
        }
        .alert("Нет доступа к камере", isPresented: $showPermissionAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Открыть настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Разрешите доступ к камере в Настройках, чтобы сделать селфи.")
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            if viewModel.step != .styles {
                Button {
                    camera.stopSession()
                    viewModel.back()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .font(.headline)
                    .foregroundStyle(BrandTheme.textPrimary)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Progress
    private var stepProgress: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.step.rawValue ? BrandTheme.accent : BrandTheme.stroke.opacity(0.6))
                    .frame(height: 6)
                    .overlay(
                        Capsule()
                            .stroke(BrandTheme.stroke.opacity(0.8), lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.step)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Steps
    private var stylesStep: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(viewModel.options) { option in
                    styleCard(option)
                }
            }
            .padding(.top, 4)
        }
    }

    private var sizesStep: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Верх")
                        .font(.subheadline).foregroundStyle(BrandTheme.textSecondary)
                    Picker("Верх", selection: Binding(get: { viewModel.topSize ?? .m }, set: { viewModel.topSize = $0 })) {
                        ForEach(OnboardingViewModel.ClothingSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Низ")
                        .font(.subheadline).foregroundStyle(BrandTheme.textSecondary)
                    Picker("Низ", selection: Binding(get: { viewModel.bottomSize ?? .m }, set: { viewModel.bottomSize = $0 })) {
                        ForEach(OnboardingViewModel.ClothingSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Обувь (EU)")
                    .font(.subheadline).foregroundStyle(BrandTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.shoeSizes, id: \.self) { size in
                            let selected = viewModel.shoeSize == size
                            Button {
                                viewModel.shoeSize = selected ? nil : size
                            } label: {
                                Text("\(size)")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(selected ? .white : BrandTheme.textPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selected ? BrandTheme.accent : BrandTheme.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(BrandTheme.stroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var heightStep: some View {
        VStack(spacing: 12) {
            Text("Выберите ваш рост (см)")
                .font(.subheadline)
                .foregroundStyle(BrandTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Spacer()
                Picker("Рост", selection: Binding(get: {
                    viewModel.height ?? 170
                }, set: { newValue in
                    viewModel.height = newValue
                })) {
                    ForEach(viewModel.heightRange, id: \.self) { h in
                        Text("\(h)").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                Text("см")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.textPrimary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var colorsStep: some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]
        return VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(OnboardingViewModel.ColorTag.allCases) { tag in
                    colorChip(tag)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var budgetStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Бюджет")
                    .font(.subheadline).foregroundStyle(BrandTheme.textSecondary)
                Picker("Бюджет", selection: Binding(get: { viewModel.budget ?? .medium }, set: { viewModel.budget = $0 })) {
                    ForEach(OnboardingViewModel.Budget.allCases) { b in
                        Text(b.title).tag(b)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Частота покупок")
                    .font(.subheadline).foregroundStyle(BrandTheme.textSecondary)
                Picker("Частота", selection: Binding(get: { viewModel.frequency ?? .monthly }, set: { viewModel.frequency = $0 })) {
                    ForEach(OnboardingViewModel.Frequency.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var selfieStep: some View {
        // Больше круг — адаптивно по ширине экрана
        let diameter = min(UIScreen.main.bounds.width - 64, 340)

        return VStack(spacing: 16) {
            // Превью — круг
            ZStack {
                Circle()
                    .fill(BrandTheme.surface)
                    .frame(width: diameter, height: diameter)
                    .overlay(Circle().stroke(BrandTheme.stroke, lineWidth: 1))

                if let img = viewModel.selfieImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: diameter - 6, height: diameter - 6)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                } else if cameraAuthStatus == .authorized {
                    InlineCameraView(session: camera.session)
                        .clipShape(Circle())
                        .frame(width: diameter - 6, height: diameter - 6)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                } else if cameraAuthStatus == .denied || cameraAuthStatus == .restricted {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(BrandTheme.textSecondary.opacity(0.8))
                        Text("Включите доступ к камере")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.textSecondary)
                    }
                } else {
                    ProgressView().tint(BrandTheme.accent)
                }
            }

            if viewModel.selfieImage == nil {
                // Кнопка спуска затвора (только при авторизованной камере)
                if cameraAuthStatus == .authorized {
                    Button {
                        camera.capture { image in
                            if let image {
                                viewModel.setSelfie(image: image)
                                camera.stopSession()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.next()
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 76, height: 76)
                                .shadow(color: .red.opacity(0.35), radius: 14, x: 0, y: 8)
                            Circle()
                                .stroke(Color.white.opacity(0.9), lineWidth: 3)
                                .frame(width: 76, height: 76)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else if cameraAuthStatus == .denied || cameraAuthStatus == .restricted {
                    Button("Открыть настройки") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrandTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var summaryStep: some View {
        VStack(spacing: 16) {
            // Фото сверху
            ZStack {
                Circle()
                    .fill(BrandTheme.surface)
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(BrandTheme.stroke, lineWidth: 1))

                if let img = viewModel.selfieImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 114, height: 114)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundStyle(BrandTheme.textSecondary.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Стили")
                        .font(.headline)
                    if viewModel.selected.isEmpty {
                        Text("Не выбрано").foregroundStyle(BrandTheme.textSecondary)
                    } else {
                        Text(viewModel.selected.map { $0.title }.joined(separator: ", "))
                    }
                }

                Group {
                    Text("Размеры")
                    .font(.headline)
                    Text("Верх: \(viewModel.topSize?.title ?? "—"), Низ: \(viewModel.bottomSize?.title ?? "—"), Обувь: \(viewModel.shoeSize.map(String.init) ?? "—")")
                        .foregroundStyle(BrandTheme.textPrimary)
                }

                Group {
                    Text("Рост")
                        .font(.headline)
                    Text("\(viewModel.height ?? 170) см")
                        .foregroundStyle(BrandTheme.textPrimary)
                }

                Group {
                    Text("Цвета")
                        .font(.headline)
                    if viewModel.preferredColors.isEmpty {
                        Text("Не выбрано").foregroundStyle(BrandTheme.textSecondary)
                    } else {
                        Text(viewModel.preferredColors.map { $0.title }.joined(separator: ", "))
                    }
                }

                Group {
                    Text("Бюджет и частота")
                        .font(.headline)
                    Text("\(viewModel.budget?.title ?? "—"), \(viewModel.frequency?.title ?? "—")")
                        .foregroundStyle(BrandTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Кнопка завершения в резюме
            Button(action: finish) {
                HStack {
                    if viewModel.isSubmitting { ProgressView().tint(.white) }
                    Text("Завершить")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(BrandTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isSubmitting)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    // MARK: - Controls (теперь не показываем "Далее" на резюме)
    private var controls: some View {
        HStack(spacing: 12) {
            if viewModel.canSkip {
                Button(action: { viewModel.skip() }) {
                    Text("Пропустить")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.textSecondary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandTheme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if viewModel.step != .summary {
                Button(action: { viewModel.next() }) {
                    Text("Далее")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canGoNext ? BrandTheme.accent : BrandTheme.stroke)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canGoNext)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Camera permission / setup
    private func prepareCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthStatus = status
        switch status {
        case .authorized:
            camera.configureForFrontCamera()
            camera.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAuthStatus = granted ? .authorized : .denied
                    if granted {
                        camera.configureForFrontCamera()
                        camera.startSession()
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func styleCard(_ option: StyleOption) -> some View {
        let isSelected = viewModel.selected.contains(option)
        Button {
            viewModel.toggle(option)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.textPrimary)
                Text(option.subtitle)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.textSecondary)
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .black : BrandTheme.textSecondary)
                        .font(.title3)
                        .padding(6)
                        .background(isSelected ? Color.white : Color.clear)
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BrandTheme.textPrimary.opacity(0.8) : BrandTheme.stroke, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    @ViewBuilder
    private func colorChip(_ tag: OnboardingViewModel.ColorTag) -> some View {
        let selected = viewModel.preferredColors.contains(tag)
        Button {
            viewModel.toggleColor(tag)
        } label: {
            VStack {
                Circle()
                    .fill(tag.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(BrandTheme.stroke, lineWidth: 1)
                    )
                Text(tag.title)
                    .font(.caption)
                    .foregroundStyle(BrandTheme.textPrimary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(BrandTheme.surface.opacity(selected ? 1 : 0.9), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? BrandTheme.textPrimary.opacity(0.9) : BrandTheme.stroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        Task { await viewModel.submitAll() }
    }
}

#Preview {
    OnboardingView(user: .init(id: "1", email: "demo@clothium.app")) {}
}
