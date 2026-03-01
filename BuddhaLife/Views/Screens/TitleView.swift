import SwiftUI

// MARK: - Country Data

private struct CountryInfo: Identifiable {
    let id: String
    let name: String
    let flag: String
    let teaser: String
}

private let countries: [CountryInfo] = [
    CountryInfo(id: "thailand", name: "Thailand", flag: "🇹🇭",
                teaser: "Gilded temples, spirit houses, and the Land of Smiles."),
    CountryInfo(id: "myanmar", name: "Myanmar", flag: "🇲🇲",
                teaser: "Ancient Bagan pagodas and deep monastic devotion."),
    CountryInfo(id: "cambodia", name: "Cambodia", flag: "🇰🇭",
                teaser: "Angkor heritage and Buddhist resilience reborn."),
    CountryInfo(id: "vietnam", name: "Vietnam", flag: "🇻🇳",
                teaser: "Mahayana, Theravada, and Confucian values intertwined."),
    CountryInfo(id: "laos", name: "Laos", flag: "🇱🇦",
                teaser: "Dawn alms rounds in the quiet heart of Indochina."),
]

// MARK: - Name Data

private let namesByCountry: [String: [String: [String]]] = [
    "thailand": [
        "male": ["Somchai", "Arthit", "Nattapong", "Prasert", "Kittisak", "Wichai", "Sompong", "Tanakorn", "Prayut", "Surasak"],
        "female": ["Siriporn", "Malai", "Nanthana", "Kanokwan", "Ploy", "Arunee", "Suwannee", "Duangjai", "Ratchanee", "Kanya"],
    ],
    "myanmar": [
        "male": ["Aung", "Kyaw", "Zaw", "Htun", "Maung", "Thet", "Ye", "Naing", "Myo", "Ko Ko"],
        "female": ["Aye", "Khin", "Tin", "May", "Nwe", "Su", "Wai", "Phyu", "Cho", "Hla"],
    ],
    "cambodia": [
        "male": ["Sokha", "Chanthea", "Vibol", "Rith", "Dara", "Piseth", "Rithy", "Kosal", "Chamroeun", "Vanna"],
        "female": ["Sreymom", "Chantrea", "Bopha", "Kunthea", "Srey Leak", "Malis", "Kolab", "Channary", "Theary", "Rachana"],
    ],
    "vietnam": [
        "male": ["Minh", "Duc", "Thanh", "Hieu", "Hung", "Tuan", "Quang", "Long", "Duy", "Phong"],
        "female": ["Lan", "Mai", "Huong", "Linh", "Thao", "Ngoc", "Anh", "Trang", "Ha", "Phuong"],
    ],
    "laos": [
        "male": ["Bounmy", "Khampha", "Somphet", "Vilay", "Keo", "Somphone", "Bounsang", "Thongkham", "Phet", "Souphanouvong"],
        "female": ["Bouachanh", "Khamla", "Chansouk", "Viengkham", "Dao", "Keo", "Souliya", "Manivanh", "Phimpha", "Noi"],
    ],
]

// MARK: - TitleView

struct TitleView: View {
    @Bindable var engine: GameEngine

    @State private var step = 0
    @State private var selectedCountry: String? = nil

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if step == 0 {
                titleStep
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                countrySelectionStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    // MARK: - Step 0: Title

    private var titleStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("\u{2638}\u{FE0F}")
                    .font(.system(size: 64))

                Text("BuddhaLife")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Color("TextPrimary"))

                Text("Live a Buddhist life in Southeast Asia")
                    .font(.system(size: 16))
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        step = 1
                    }
                } label: {
                    Text("New Life")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())

                if PersistenceManager.hasSave() {
                    Button {
                        engine.restoreSave()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color("AccentColor"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("BgSecondary"), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("AccentColor"), lineWidth: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 48)
    }

    // MARK: - Step 1: Country Selection

    private var countrySelectionStep: some View {
        VStack(spacing: 0) {
            Text("Choose Your Country")
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(Color("TextPrimary"))
                .padding(.top, 48)

            Text("Where will your life begin?")
                .font(.system(size: 16))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.top, 6)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(countries) { country in
                        countryCard(country)
                    }
                }
                .padding(.top, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            Spacer(minLength: 0)

            Button {
                beginLife()
            } label: {
                Text("Begin Life")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Color("AccentColor").opacity(selectedCountry != nil ? 1 : 0.4),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(selectedCountry == nil)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Country Card

    private func countryCard(_ country: CountryInfo) -> some View {
        let isSelected = selectedCountry == country.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCountry = country.id
            }
        } label: {
            HStack(spacing: 14) {
                Text(country.flag)
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color("TextPrimary"))

                    Text(country.teaser)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("TextSecondary"))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Begin Life

    private func beginLife() {
        guard let countryId = selectedCountry else { return }

        let gender = Bool.random() ? "male" : "female"
        let countryNames = namesByCountry[countryId]?[gender]
            ?? namesByCountry["thailand"]!["male"]!
        let name = countryNames.randomElement() ?? "Somchai"

        // Load backgrounds from bundled JSON
        let background = loadRandomBackground(for: countryId)

        let birthYear = 2000 + Int.random(in: 0..<10)

        let config = CharacterConfig(
            name: name,
            country: countryId,
            background: background,
            birthYear: birthYear,
            gender: gender
        )

        engine.startGame(config: config)
    }

    // MARK: - Background Loading

    private func loadRandomBackground(for country: String) -> String {
        guard let url = Bundle.main.url(forResource: "backgrounds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let allBackgrounds = try? JSONDecoder().decode(BackgroundsByCountry.self, from: data),
              let countryBackgrounds = allBackgrounds[country],
              !countryBackgrounds.isEmpty else {
            return "unknown"
        }
        return countryBackgrounds.randomElement()?.id ?? "unknown"
    }
}

// MARK: - Scale Button Style

/// A button style that gently scales on press, matching the web app's mouseDown behavior.
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    TitleView(engine: GameEngine())
}
