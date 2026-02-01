import WidgetKit
import SwiftUI

// NOTE: This widget extension must be added to the Xcode project manually.
// In Xcode: File > New > Target > Widget Extension, name it "SilniStreakWidget",
// then replace the generated code with this file's contents.
// Also ensure the App Group "group.com.silni.app.widget" is enabled for both
// the Runner target and the SilniStreakWidget target in Signing & Capabilities.

struct StreakEntry: TimelineEntry {
    let date: Date
    let displayName: String
    let streakCount: Int
    let streakText: String
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), displayName: "\u{0635}\u{0650}\u{0644}\u{0646}\u{064A}", streakCount: 0, streakText: "\u{0635}\u{0650}\u{0644}\u{0646}\u{064A} \u{1F525}\u{0660}")
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = readEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = readEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func readEntry() -> StreakEntry {
        let defaults = UserDefaults(suiteName: "group.com.silni.app.widget")
        let name = defaults?.string(forKey: "display_name") ?? "\u{0635}\u{0650}\u{0644}\u{0646}\u{064A}"
        let count = defaults?.integer(forKey: "streak_count") ?? 0
        let text = defaults?.string(forKey: "streak_text") ?? "\u{0635}\u{0650}\u{0644}\u{0646}\u{064A} \u{1F525}\u{0660}"
        return StreakEntry(date: Date(), displayName: name, streakCount: count, streakText: text)
    }
}

struct SilniStreakWidgetEntryView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.30, blue: 0.15), Color(red: 0.08, green: 0.45, blue: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                Text("\u{1F525}")
                    .font(.system(size: family == .systemSmall ? 28 : 36))

                Text("\(entry.streakCount)")
                    .font(.system(size: family == .systemSmall ? 24 : 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .environment(\.locale, Locale(identifier: "ar"))

                Text(entry.displayName)
                    .font(.system(size: family == .systemSmall ? 12 : 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(8)
        }
    }
}

struct SilniStreakWidget: Widget {
    let kind: String = "SilniStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            SilniStreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("\u{0635}\u{0650}\u{0644}\u{0646}\u{064A} - \u{0623}\u{0639}\u{0644}\u{0649} \u{0633}\u{0644}\u{0633}\u{0644}\u{0629}")
        .description("\u{0639}\u{0631}\u{0636} \u{0623}\u{0639}\u{0644}\u{0649} \u{0633}\u{0644}\u{0633}\u{0644}\u{0629} \u{062A}\u{0648}\u{0627}\u{0635}\u{0644} \u{0645}\u{0639} \u{0623}\u{0642}\u{0627}\u{0631}\u{0628}\u{0643}")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
