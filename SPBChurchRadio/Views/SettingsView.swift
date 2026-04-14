import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAbout = false
    @State private var showHelp = false

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: isIPad ? 24 : 18) {
                        // MARK: - Theme Section
                        settingsSectionHeader("Оформление")
                        themeSection

                        // MARK: - Help Section
                        settingsSectionHeader("Помощь")
                        helpSection

                        // MARK: - Links Section
                        settingsSectionHeader("Ссылки")
                        linksSection

                        // MARK: - About Section
                        settingsSectionHeader("О приложении")
                        aboutSection
                    }
                    .padding(.horizontal, isIPad ? 32 : 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Настройки")
            .toolbarTitleDisplayMode(.large)
            .tint(AppColors.accentAdaptive)
            .fullScreenCover(isPresented: $showAbout) {
                AboutAppView()
            }
            .fullScreenCover(isPresented: $showHelp) {
                HelpView()
            }
        }
    }

    // MARK: - Help Section

    private var helpSection: some View {
        Button(action: {
            HapticManager.lightImpact()
            showHelp = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: isIPad ? 44 : 38, height: isIPad ? 44 : 38)
                        .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)

                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Руководство пользователя")
                        .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Описание функций и подсказки")
                        .font(.system(size: isIPad ? 13 : 12, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, isIPad ? 20 : 16)
            .padding(.vertical, isIPad ? 14 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .neumorphicRaised(cornerRadius: 16)
    }

    // MARK: - Section Header

    private func settingsSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(1)
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(spacing: 0) {
            ForEach(ThemeManager.ThemeMode.allCases) { mode in
                themeRow(mode: mode)
            }
        }
        .neumorphicRaised(cornerRadius: 16)
    }

    @ViewBuilder
    private func themeRow(mode: ThemeManager.ThemeMode) -> some View {
        Button(action: {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                themeManager.mode = mode
            }
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: isIPad ? 44 : 38, height: isIPad ? 44 : 38)
                        .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)

                    Image(systemName: mode.iconName)
                        .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                        .foregroundStyle(themeManager.mode == mode ? AppColors.accentAdaptive : AppColors.textSecondary)
                }

                Text(mode.displayName)
                    .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                // Checkmark
                if themeManager.mode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isIPad ? 22 : 20))
                        .foregroundStyle(AppColors.accentAdaptive)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, isIPad ? 20 : 16)
            .padding(.vertical, isIPad ? 14 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        // Divider between rows (not after last)
        if mode != ThemeManager.ThemeMode.allCases.last {
            Divider()
                .background(AppColors.textSecondary.opacity(0.15))
                .padding(.leading, isIPad ? 72 : 62)
        }
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(spacing: 0) {
            linkRow(
                title: "Радиостанция",
                subtitle: "station.spbchurch.ru",
                icon: "antenna.radiowaves.left.and.right",
                url: URL(string: "https://station.spbchurch.ru/")!
            )

            Divider()
                .background(AppColors.textSecondary.opacity(0.15))
                .padding(.leading, isIPad ? 72 : 62)

            linkRow(
                title: "Церковь «Преображение»",
                subtitle: "spbchurch.ru",
                icon: "cross.fill",
                url: URL(string: "https://spbchurch.ru/")!
            )
        }
        .neumorphicRaised(cornerRadius: 16)
    }

    private func linkRow(title: String, subtitle: String, icon: String, url: URL) -> some View {
        Button(action: {
            HapticManager.lightImpact()
            UIApplication.shared.open(url)
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: isIPad ? 44 : 38, height: isIPad ? 44 : 38)
                        .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)

                    Image(systemName: icon)
                        .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: isIPad ? 13 : 12, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, isIPad ? 20 : 16)
            .padding(.vertical, isIPad ? 14 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(spacing: 0) {
            // App info row
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: isIPad ? 44 : 38, height: isIPad ? 44 : 38)
                        .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)

                    Image(systemName: "info.circle.fill")
                        .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("SPBChurch Radio")
                        .font(.system(size: isIPad ? 17 : 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Версия 3.12")
                        .font(.system(size: isIPad ? 13 : 12, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, isIPad ? 20 : 16)
            .padding(.top, isIPad ? 14 : 12)
            .padding(.bottom, 10)

            Divider()
                .background(AppColors.textSecondary.opacity(0.15))
                .padding(.horizontal, isIPad ? 20 : 16)

            // About button
            Button(action: {
                HapticManager.lightImpact()
                showAbout = true
            }) {
                HStack {
                    Text("Описание приложения")
                        .font(.system(size: isIPad ? 15 : 14, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                }
                .padding(.horizontal, isIPad ? 20 : 16)
                .padding(.vertical, isIPad ? 14 : 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .neumorphicRaised(cornerRadius: 16)
    }
}

// MARK: - About App View (Full Screen)

private struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("О приложении")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Button(action: {
                        HapticManager.lightImpact()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: isIPad ? 28 : 22) {
                        // App icon area
                        appIconSection

                        // Description card
                        descriptionCard

                        // Features card
                        featuresCard

                        // Credits card
                        creditsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var appIconSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.accentAdaptive.opacity(0.2),
                                AppColors.accentAdaptive.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image("TreeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 10, x: 5, y: 5)
            }

            Text("SPBChurch Radio")
                .font(.system(size: isIPad ? 24 : 20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Версия 3.12")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("О приложении", systemImage: "text.quote")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.accentAdaptive)

            Text("SPBChurch Radio — мобильное приложение для прослушивания христианского интернет-радио: псалмы, духовные песни и прямой эфир в любое время и в любом месте.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                .lineSpacing(4)

            Text("Слушайте прямой эфир с отображением текущего трека в реальном времени, просматривайте каталог из более чем 2000 аудиозаписей, создавайте собственные плейлисты с помощью функции случайного воспроизведения, добавляйте треки в избранное и загружайте любимые песни для офлайн-прослушивания — всё это доступно без регистрации и подписок.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                .lineSpacing(4)

            Text("Приложение поддерживает фоновое воспроизведение, управление с экрана блокировки и через наушники, а также адаптируется под любой размер экрана — от компактного iPhone до iPad.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(isIPad ? 24 : 18)
        .neumorphicRaised(cornerRadius: 16)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Возможности", systemImage: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.accentAdaptive)

            featureRow(icon: "antenna.radiowaves.left.and.right", text: "Прямой эфир радиостанции с метаданными треков")
            featureRow(icon: "music.note.list", text: "Каталог 2000+ аудиозаписей с поиском")
            featureRow(icon: "shuffle", text: "Случайное и последовательное воспроизведение")
            featureRow(icon: "arrow.down.circle.fill", text: "Загрузка треков для офлайн-прослушивания")
            featureRow(icon: "speaker.wave.2.fill", text: "Фоновое воспроизведение и управление с Lock Screen")
            featureRow(icon: "moon.fill", text: "Тёмная и светлая темы оформления")
            featureRow(icon: "ipad.and.iphone", text: "Адаптивный интерфейс для iPhone и iPad")
        }
        .padding(isIPad ? 24 : 18)
        .neumorphicRaised(cornerRadius: 16)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.accentAdaptive)
                .frame(width: 24)

            Text(text)
                .font(.system(size: isIPad ? 15 : 13, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))

            Spacer(minLength: 0)
        }
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Благодарности", systemImage: "heart.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.accentAdaptive)

            Text("Приложение создано христианами, которые неравнодушны к псалмам и духовным песням, — с любовью к музыке, вниманием к деталям и желанием поделиться ею с ближними.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                .lineSpacing(4)

            Text("Иллюстрация «Древо с корнями» символизирует духовное возрастание и укоренение в вере — центральный визуальный мотив приложения.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                .lineSpacing(4)

            HStack(spacing: 6) {
                Image(systemName: "cross.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accentAdaptive)
                Text("Слава Богу за всё.")
                    .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, 4)
        }
        .padding(isIPad ? 24 : 18)
        .neumorphicRaised(cornerRadius: 16)
    }
}

// MARK: - Help View (Full Screen)

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Помощь")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Button(action: {
                        HapticManager.lightImpact()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: isIPad ? 20 : 16) {
                        helpSection(
                            title: "Радио",
                            icon: "antenna.radiowaves.left.and.right",
                            items: [
                                HelpItem(icon: "play.circle.fill", text: "Нажмите большую круглую кнопку в центре экрана, чтобы запустить прямой эфир. Повторное нажатие — остановка."),
                                HelpItem(icon: "tree.fill", text: "Когда идёт эфир, иллюстрация дерева светится золотом — это визуальный индикатор живого потока."),
                                HelpItem(icon: "waveform", text: "Под кнопкой отображается название текущего трека из метаданных станции."),
                                HelpItem(icon: "magnifyingglass", text: "Кнопка «Найти в библиотеке» переключает на вкладку «Треки» и подставляет название играющего трека в поиск."),
                                HelpItem(icon: "chevron.up", text: "Карточка играющего файла внизу открывает полноэкранный плеер при нажатии.")
                            ]
                        )

                        helpSection(
                            title: "Треки",
                            icon: "music.note.list",
                            items: [
                                HelpItem(icon: "magnifyingglass", text: "Поиск фильтрует каталог по названию в реальном времени."),
                                HelpItem(icon: "arrow.up.arrow.down.circle", text: "Меню сортировки в правом углу: по умолчанию, А–Я, Я–А. Выбор сохраняется."),
                                HelpItem(icon: "heart", text: "Сердечко в строке трека добавляет его в избранное одним тапом."),
                                HelpItem(icon: "arrow.down.circle", text: "Стрелка загружает трек в офлайн; круговой прогресс показывает ход загрузки и останавливается по тапу."),
                                HelpItem(icon: "play.circle", text: "Круглая кнопка play запускает воспроизведение — очередь уважает текущий порядок сортировки и поиска."),
                                HelpItem(icon: "hand.tap", text: "Долгий тап открывает контекстное меню с действиями «Поделиться» и «Избранное».")
                            ]
                        )

                        helpSection(
                            title: "Избранное",
                            icon: "heart.fill",
                            items: [
                                HelpItem(icon: "heart", text: "Добавить трек: нажмите ♡ в строке во вкладке «Треки» или из «Действий» на экране плеера."),
                                HelpItem(icon: "arrow.down.circle", text: "Скачивать и делиться треками можно прямо из избранного — кнопки встроены в строку."),
                                HelpItem(icon: "arrow.up.arrow.down", text: "Кнопка «Изменить» в toolbar включает reorder и swipe-to-delete."),
                                HelpItem(icon: "tray.full", text: "Список хранится локально (`favorites.json`) и работает без интернета.")
                            ]
                        )

                        helpSection(
                            title: "Загрузки",
                            icon: "arrow.down.circle.fill",
                            items: [
                                HelpItem(icon: "wifi.slash", text: "Загруженные треки доступны без интернета и сохраняются между запусками — список не зависит от каталога."),
                                HelpItem(icon: "square.and.arrow.up", text: "Кнопка Share в каждой строке открывает стандартный share-sheet с MP3 файлом (AirDrop, Messages, Files и т.д.)."),
                                HelpItem(icon: "trash", text: "Удалить трек с устройства — иконка корзины в строке или свайп."),
                                HelpItem(icon: "internaldrive", text: "Каждый трек хранится по хэшу URL — дубликаты исключены.")
                            ]
                        )

                        helpSection(
                            title: "Плеер",
                            icon: "play.circle.fill",
                            items: [
                                HelpItem(icon: "line.3.horizontal", text: "Левый нижний виджет «Действия» — меню с добавлением в избранное, скачиванием и кнопкой «Поделиться файлом»."),
                                HelpItem(icon: "shuffle", text: "Правый виджет переключает порядок воспроизведения: Микс (случайный), Повтор (зацикливание), До конца (остановка после последнего трека). Выбор сохраняется."),
                                HelpItem(icon: "slider.horizontal.below.rectangle", text: "Слайдер прогресса над iPod-колесом можно тянуть для перемотки."),
                                HelpItem(icon: "backward.fill", text: "Стрелки вперёд/назад на колесе переключают треки в пределах текущего плейлиста (очередь запоминает, откуда стартовало воспроизведение)."),
                                HelpItem(icon: "chevron.down", text: "Chevron вверху закрывает плеер — воспроизведение продолжается, а под списками появляется мини-плеер.")
                            ]
                        )

                        helpSection(
                            title: "Настройки и фон",
                            icon: "gearshape.fill",
                            items: [
                                HelpItem(icon: "moon.fill", text: "Тема приложения: системная / светлая / тёмная — переключается в «Настройки › Оформление»."),
                                HelpItem(icon: "lock.fill", text: "Приложение продолжает играть при блокировке экрана."),
                                HelpItem(icon: "applewatch", text: "Управление с Lock Screen, Control Center и совместимых наушников."),
                                HelpItem(icon: "ipad.and.iphone", text: "Адаптивный макет для iPhone и iPad во всех ориентациях.")
                            ]
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func helpSection(title: String, icon: String, items: [HelpItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.accentAdaptive)

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)
                        .frame(width: 24)
                        .padding(.top, 1)

                    Text(item.text)
                        .font(.system(size: isIPad ? 15 : 13, weight: .regular))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(isIPad ? 24 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicRaised(cornerRadius: 16)
    }
}

private struct HelpItem: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}
