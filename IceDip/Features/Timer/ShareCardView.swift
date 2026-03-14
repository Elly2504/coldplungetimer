import SwiftUI

struct ShareCardView: View {
    let duration: String
    let zone: BenefitZone?
    let date: Date

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "snowflake")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "64D2FF"))

            Text("IceDip")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(duration)
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundStyle(Color(hex: "64D2FF"))

            Text("Cold Plunge Complete")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            if let zone {
                HStack(spacing: 8) {
                    Image(systemName: zone.icon)
                        .foregroundStyle(zone.color)
                    Text(zone.displayName)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(zone.color)
                }
            }

            Text(date.formattedShort)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
        .padding(40)
        .frame(width: 400, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "0A1628"))
        )
    }
}
