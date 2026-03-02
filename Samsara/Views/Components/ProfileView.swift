import SwiftUI

// MARK: - ProfileView
//
// Ports the ProfileTab inline component from GameScreen.jsx.
//
// Layout (top to bottom):
//   1. Large centered avatar emoji
//   2. Character name (bold heading)
//   3. "Age N . Life Stage" subtitle
//   4. Country flag + country name
//   5. Background description card (if background exists)
//   6. Details card (birth year, gender)
//   7. Relationships section — each NPC with name, type, affinity bar, alive/dead

struct ProfileView: View {

    @Bindable var engine: GameEngine

    // MARK: - Derived State

    private var character: Character { engine.character }
    private var age: Int { character.age }

    private var avatar: String {
        avatarEmoji(age: age, gender: character.gender)
    }

    private var stage: String {
        lifeStageDisplayName(engine.lifeStage)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Avatar
            Text(avatar)
                .font(.system(size: 64))
                .padding(.top, 24)

            // Name
            Text(character.name.isEmpty ? "Unknown" : character.name)
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.48)
                .foregroundStyle(Color("TextPrimary"))
                .padding(.top, 12)

            // Age + life stage
            Text("Age \(age) \u{00B7} \(stage)")
                .font(.system(size: 16))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.top, 4)

            // Country
            Text("\(countryFlag(character.country)) \(countryDisplayName(character.country))")
                .font(.system(size: 16))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.top, 4)

            // Background card
            if !character.background.isEmpty {
                infoCard(header: "Background") {
                    Text(backgroundLabel(for: character.background))
                        .font(.system(size: 14))
                        .foregroundStyle(Color("TextPrimary"))
                        .lineSpacing(4)
                }
                .padding(.top, 24)
            }

            // Details card
            infoCard(header: "Details") {
                VStack(alignment: .leading, spacing: 6) {
                    detailRow(label: "Born", value: character.birthYear > 0 ? "\(character.birthYear)" : "---")
                    detailRow(label: "Gender", value: character.gender.isEmpty ? "---" : character.gender.capitalized)
                }
            }
            .padding(.top, 16)

            // Relationships section
            if !engine.relationships.isEmpty {
                relationshipsSection
                    .padding(.top, 24)
            }

            Spacer(minLength: 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Info Card

    /// Reusable card component matching the gray rounded box from ProfileTab JSX.
    private func infoCard<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color("TextSecondary"))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("BgSecondary"))
        )
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .foregroundStyle(Color("TextSecondary"))
            Text(value)
                .foregroundStyle(Color("TextPrimary"))
        }
        .font(.system(size: 14))
    }

    // MARK: - Background Label

    /// Resolve a background ID to its human-readable label by loading backgrounds.json.
    /// Falls back to the raw ID if the lookup fails.
    private func backgroundLabel(for backgroundId: String) -> String {
        guard let url = (Bundle.main.url(forResource: "backgrounds", withExtension: "json", subdirectory: "Resources") ??
              Bundle.main.url(forResource: "backgrounds", withExtension: "json")),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode(BackgroundsByCountry.self, from: data) else {
            return backgroundId
        }
        for backgrounds in dict.values {
            if let match = backgrounds.first(where: { $0.id == backgroundId }) {
                return match.label
            }
        }
        return backgroundId
    }

    // MARK: - Relationships Section

    private var relationshipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATIONSHIPS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color("TextSecondary"))
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(engine.relationships) { relationship in
                    relationshipRow(relationship)
                }
            }
        }
    }

    // MARK: - Relationship Row

    private func relationshipRow(_ relationship: Relationship) -> some View {
        HStack(spacing: 12) {
            // Name and type
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(relationship.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("TextPrimary"))

                    // Living/dead indicator
                    if !relationship.alive {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }

                Text(relationshipTypeLabel(relationship))
                    .font(.system(size: 13))
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer()

            // Affinity bar
            affinityBar(value: relationship.affinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("BgSecondary"))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Relationship Type Label

    private func relationshipTypeLabel(_ relationship: Relationship) -> String {
        if let role = relationship.role, !role.isEmpty {
            return role.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return relationship.type.capitalized
    }

    // MARK: - Affinity Bar

    private func affinityBar(value: Int) -> some View {
        let clamped = max(0, min(100, value))
        let fraction = Double(clamped) / 100.0

        return HStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    Capsule()
                        .fill(affinityColor(clamped))
                        .frame(width: geometry.size.width * fraction, height: 6)
                        .animation(.easeOut(duration: 0.5), value: clamped)
                }
            }
            .frame(width: 60, height: 6)

            Text("\(clamped)")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color("TextSecondary"))
                .frame(width: 24, alignment: .trailing)
        }
    }

    /// Affinity color: red (low) -> orange (mid) -> green (high).
    private func affinityColor(_ value: Int) -> Color {
        if value < 30 {
            return Color(red: 1.0, green: 0.231, blue: 0.188) // red
        }
        if value < 60 {
            return Color.accentColor // saffron
        }
        return Color(red: 0.204, green: 0.780, blue: 0.349) // green
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ProfileView(engine: GameEngine())
    }
}
