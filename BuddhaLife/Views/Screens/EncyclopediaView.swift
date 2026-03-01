import SwiftUI

// MARK: - EncyclopediaView
//
// Ports EncyclopediaScreen.jsx — a searchable, filterable glossary of Buddhist terms.
//
// Features:
//   - Loads glossary from bundled glossary.json
//   - .searchable modifier for filtering by term, Pali, translation, or description
//   - Horizontal scroll of country filter pills (All, Thailand, Myanmar, Cambodia, Vietnam, Laos)
//   - Result count
//   - Each term displayed as an expandable card via DisclosureGroup
//   - Country tags shown on each term

struct EncyclopediaView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchText: String = ""
    @State private var countryFilter: String = "all"
    @State private var glossary: [GlossaryTerm] = []
    @State private var expandedTerm: String? = nil

    // MARK: - Country Filters

    private static let countryFilters: [(id: String, label: String)] = [
        ("all",      "All"),
        ("thailand", "\u{1F1F9}\u{1F1ED} Thailand"),
        ("myanmar",  "\u{1F1F2}\u{1F1F2} Myanmar"),
        ("cambodia", "\u{1F1F0}\u{1F1ED} Cambodia"),
        ("vietnam",  "\u{1F1FB}\u{1F1F3} Vietnam"),
        ("laos",     "\u{1F1F1}\u{1F1E6} Laos"),
    ]

    // MARK: - Filtered Results

    /// Mirrors the useMemo filtering logic from EncyclopediaScreen.jsx:
    /// 1. Country filter (check countries array or country field)
    /// 2. Text search across term, pali, translation, description
    private var filtered: [GlossaryTerm] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)

        return glossary.filter { entry in
            // Country filter
            let matchesCountry: Bool
            if countryFilter == "all" {
                matchesCountry = true
            } else if let countries = entry.countries {
                matchesCountry = countries.contains(countryFilter)
            } else {
                matchesCountry = false
            }
            guard matchesCountry else { return false }

            // Text search
            guard !query.isEmpty else { return true }
            return entry.term.lowercased().contains(query)
                || (entry.pali?.lowercased().contains(query) ?? false)
                || entry.translation.lowercased().contains(query)
                || entry.description.lowercased().contains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Country filter pills
                filterPills
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Result count
                Text("\(filtered.count) \(filtered.count == 1 ? "term" : "terms") found")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // Glossary list
                if filtered.isEmpty {
                    emptyState
                } else {
                    glossaryList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Encyclopedia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search terms, Pali words..."
            )
        }
        .onAppear {
            loadGlossary()
        }
    }

    // MARK: - Filter Pills

    /// Horizontal scroll of country filter pill buttons.
    /// Mirrors the filterRow / filterPill styles from EncyclopediaScreen.jsx.
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.countryFilters, id: \.id) { filter in
                    let isActive = countryFilter == filter.id

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            countryFilter = filter.id
                        }
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            .foregroundStyle(isActive ? Color.accentColor : Color("TextSecondary"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isActive ? Color.accentColor : Color(.systemGray4),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("\u{1F4D6}")
                .font(.system(size: 32))
            Text("No terms match your search.")
                .font(.system(size: 15))
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Glossary List

    private var glossaryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { entry in
                    termCard(entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Term Card

    /// Each glossary entry as an expandable card.
    /// Tapping toggles the description visibility.
    private func termCard(_ entry: GlossaryTerm) -> some View {
        let isExpanded = expandedTerm == entry.term

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedTerm = isExpanded ? nil : entry.term
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Term name + Pali
                HStack(spacing: 0) {
                    Text(entry.term)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color("TextPrimary"))

                    if let pali = entry.pali, pali != entry.term {
                        Text(" (\(pali))")
                            .font(.system(size: 14).italic())
                            .foregroundStyle(Color("TextSecondary"))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("TextSecondary"))
                }

                // Translation
                Text(entry.translation)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .lineSpacing(2)

                // Description (expandable)
                if isExpanded {
                    Text(entry.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("TextPrimary").opacity(0.8))
                        .lineSpacing(4)
                        .padding(.top, 4)

                    // Country tags
                    if let countries = entry.countries, !countries.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(countries, id: \.self) { country in
                                Text(country.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color("TextSecondary"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Glossary

    /// Load glossary terms from the bundled glossary.json file.
    private func loadGlossary() {
        guard let url = Bundle.main.url(forResource: "glossary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([GlossaryTerm].self, from: data) else {
            return
        }
        glossary = decoded
    }
}

// MARK: - Preview

#Preview {
    EncyclopediaView()
}
