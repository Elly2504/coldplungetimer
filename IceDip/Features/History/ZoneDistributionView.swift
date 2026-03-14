import SwiftUI

struct ZoneDistributionView: View {
    let sessions: [PlungeSession]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Zone Distribution")
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            if distribution.isEmpty {
                Text("Complete sessions to see zone data")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                ForEach(distribution, id: \.zone) { item in
                    zoneRow(item)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func zoneRow(_ item: ZoneCount) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: item.zone.icon)
                .foregroundStyle(item.zone.color)
                .frame(width: 20)

            Text(item.zone.displayName)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(item.zone.color.opacity(0.6))
                    .frame(width: geo.size.width * item.fraction)
            }
            .frame(width: 80, height: 12)

            Text("\(item.count)")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private var distribution: [ZoneCount] {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return [] }

        var counts: [BenefitZone: Int] = [:]
        for session in completed {
            if let zone = session.zone {
                counts[zone, default: 0] += 1
            }
        }

        let maxCount = counts.values.max() ?? 1
        return BenefitZone.allCases.compactMap { zone in
            guard let count = counts[zone], count > 0 else { return nil }
            return ZoneCount(zone: zone, count: count, fraction: Double(count) / Double(maxCount))
        }
    }
}

private struct ZoneCount {
    let zone: BenefitZone
    let count: Int
    let fraction: Double
}
