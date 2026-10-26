import WidgetKit
import SwiftUI

// ---------------------------------------------------------------
// ホーム画面「今日の1枚」とロック画面「この日のひとこと」
// データは App Group（group.work.ltv.himekuri）の himekuri.json / img_*.jpg
// ---------------------------------------------------------------

struct Look {
    let paper: Color, binding: Color, ink: Color, ink2: Color, accent: Color
    let design: Font.Design

    static func from(_ s: HKSettings?) -> Look {
        let p: (String, String, String, String)
        switch s?.paper ?? "white" {
        case "kraft":  p = ("#d9c19a", "#9d8257", "#3b2b17", "#7a654a")
        case "washi":  p = ("#f4efe3", "#c9bea6", "#2d2a26", "#8a8278")
        case "sumi":   p = ("#202023", "#3b3a40", "#efe9dc", "#a39d92")
        case "sora":   p = ("#e8f0f7", "#a9bfd2", "#1f2d3b", "#6f8194")
        case "sakura": p = ("#fcf0f2", "#d9b3bb", "#3a2a2e", "#9a7f86")
        default:       p = ("#fbf8f1", "#d9d1c2", "#2b2824", "#8a8177")
        }
        let a: String
        switch s?.accent ?? "shu" {
        case "ai": a = "#2d4f7c"
        case "matsu": a = "#3d6b4f"
        case "kincha": a = "#b07d22"
        case "fuji": a = "#6b4c8a"
        case "sumi": a = (s?.paper == "sumi") ? "#d8d2c6" : "#3a3734"
        default: a = "#c8452c"
        }
        let design: Font.Design
        switch s?.font ?? "gothic" {
        case "mincho": design = .serif
        case "maru": design = .rounded
        default: design = .default
        }
        return Look(paper: Color(hex: p.0), binding: Color(hex: p.1), ink: Color(hex: p.2), ink2: Color(hex: p.3), accent: Color(hex: a), design: design)
    }
}

extension Color {
    init(hex: String) {
        var s = hex; if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}

struct CardEntry: TimelineEntry {
    let date: Date
    let day: HKDay
    let card: HKCard?
    let image: UIImage?
    let memory: (label: String, text: String)?
    let look: Look
    let hasData: Bool

    static func make(for date: Date) -> CardEntry {
        let data = HK.load()
        let card = data.flatMap { HK.pick(for: date, data: $0) }
        var image: UIImage? = nil
        if let c = card, c.img == true, let url = HK.imageURL(c.id) { image = UIImage(contentsOfFile: url.path) }
        return CardEntry(date: date, day: HKDay(date), card: card, image: image,
                         memory: data.flatMap { HK.memory(for: date, data: $0) },
                         look: Look.from(data?.settings), hasData: data != nil && !(data!.cards.isEmpty))
    }

    static var sample: CardEntry {
        let c = HKCard(id: "sample", text: "今日は、昨日より少しだけ。", sub: nil, kind: "any", date: nil, wdays: nil, order: 0, img: false)
        return CardEntry(date: Date(), day: HKDay(Date()), card: c, image: nil, memory: ("去年の今日", "久しぶりに早起きした。空気が澄んでいた。"), look: Look.from(nil), hasData: true)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CardEntry { .sample }
    func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
        completion(context.isPreview ? .sample : .make(for: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
        let cal = Calendar.current
        let now = Date()
        var entries = [CardEntry.make(for: now)]
        var day = cal.startOfDay(for: now)
        for _ in 0..<3 {
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
            entries.append(.make(for: day))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// ---------- 共通の部品 ----------

extension View {
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { color }
        } else {
            self.background(color)
        }
    }
}

struct BindingBar: View {
    let look: Look
    var body: some View {
        ZStack {
            Rectangle().fill(look.binding)
            HStack(spacing: 44) {
                Circle().fill(Color.black.opacity(0.28)).frame(width: 6, height: 6)
                Circle().fill(Color.black.opacity(0.28)).frame(width: 6, height: 6)
            }
        }
        .frame(height: 12)
    }
}

/// 文字量に応じて字の大きさを変える（index.html の len-s / len-l / len-xl と同じ考え方）
func textSize(_ text: String, base: CGFloat) -> CGFloat {
    let n = text.filter { !$0.isWhitespace }.count
    if n <= 14 { return base * 1.18 }
    if n > 120 { return base * 0.78 }
    if n > 50 { return base * 0.88 }
    return base
}

struct DateBlock: View {
    let entry: CardEntry
    var compact = false
    var body: some View {
        let l = entry.look
        VStack(spacing: compact ? 0 : 2) {
            if !compact {
                Text("\(String(entry.day.y))年\(entry.day.m)月").font(.system(size: 10, weight: .semibold, design: l.design)).foregroundColor(l.ink2).tracking(1.5)
            }
            Text("\(entry.day.d)").font(.system(size: compact ? 30 : 40, weight: .bold, design: l.design)).foregroundColor(l.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(HK.weekdaysLong[entry.day.weekday]).font(.system(size: compact ? 9 : 10, weight: .bold, design: l.design)).foregroundColor(l.accent).tracking(2)
            Rectangle().fill(l.accent).frame(width: 22, height: 2).padding(.top, compact ? 3 : 5)
        }
    }
}

struct EmptyHint: View {
    let look: Look
    var body: some View {
        Text("アプリでカードを作ると\nここに1枚ずつ出ます").font(.system(size: 11, weight: .medium, design: look.design)).foregroundColor(look.ink2).multilineTextAlignment(.center).lineSpacing(2)
    }
}

// ---------- ホーム画面：今日の1枚 ----------

struct PhotoSheet: View {
    let entry: CardEntry
    let image: UIImage
    let family: WidgetFamily
    var body: some View {
        let large = family == .systemLarge
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image).resizable().scaledToFill()
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(entry.day.d)").font(.system(size: large ? 34 : 24, weight: .bold, design: entry.look.design))
                    Text(HK.weekdaysLong[entry.day.weekday]).font(.system(size: 10, weight: .bold, design: entry.look.design)).tracking(1.5)
                }
                if let t = entry.card?.text, !t.isEmpty {
                    Text(t).font(.system(size: large ? 15 : 12, weight: .medium, design: entry.look.design)).lineLimit(large ? 4 : 2).minimumScaleFactor(0.8)
                }
            }
            .foregroundColor(.white).shadow(color: .black.opacity(0.4), radius: 3, y: 1)
            .padding(large ? 16 : 12)
        }
    }
}

struct SmallSheet: View {
    let entry: CardEntry
    var body: some View {
        let l = entry.look
        if let img = entry.image {
            PhotoSheet(entry: entry, image: img, family: .systemSmall)
        } else {
            VStack(spacing: 0) {
                BindingBar(look: l)
                VStack(spacing: 6) {
                    DateBlock(entry: entry, compact: true)
                    if let c = entry.card, !c.text.isEmpty {
                        Text(c.text).font(.system(size: textSize(c.text, base: 13), weight: .medium, design: l.design)).foregroundColor(l.ink)
                            .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.7).lineSpacing(2)
                    } else if !entry.hasData {
                        EmptyHint(look: l)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 8)
            }
        }
    }
}

struct MediumSheet: View {
    let entry: CardEntry
    var body: some View {
        let l = entry.look
        if let img = entry.image {
            PhotoSheet(entry: entry, image: img, family: .systemMedium)
        } else {
            VStack(spacing: 0) {
                BindingBar(look: l)
                HStack(spacing: 14) {
                    DateBlock(entry: entry).frame(width: 84)
                    Rectangle().fill(l.binding).frame(width: 1).padding(.vertical, 6)
                    VStack(alignment: .leading, spacing: 4) {
                        if let c = entry.card, !c.text.isEmpty {
                            Text(c.text).font(.system(size: textSize(c.text, base: 15), weight: .medium, design: l.design)).foregroundColor(l.ink)
                                .lineLimit(4).minimumScaleFactor(0.7).lineSpacing(3)
                            if let s = c.sub, !s.isEmpty {
                                Text(s).font(.system(size: 10, design: l.design)).foregroundColor(l.ink2).lineLimit(1)
                            }
                        } else if !entry.hasData {
                            EmptyHint(look: l)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
            }
        }
    }
}

struct LargeSheet: View {
    let entry: CardEntry
    var body: some View {
        let l = entry.look
        VStack(spacing: 0) {
            BindingBar(look: l)
            VStack(spacing: 8) {
                DateBlock(entry: entry)
                Spacer(minLength: 4)
                if let img = entry.image {
                    Image(uiImage: img).resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: 150).clipped().cornerRadius(10)
                }
                if let c = entry.card, !c.text.isEmpty {
                    Text(c.text).font(.system(size: entry.image != nil ? 14 : textSize(c.text, base: 19), weight: .medium, design: l.design)).foregroundColor(l.ink)
                        .multilineTextAlignment(.center).lineLimit(entry.image != nil ? 3 : 9).minimumScaleFactor(0.7).lineSpacing(4)
                    if let s = c.sub, !s.isEmpty {
                        Text(s).font(.system(size: 10, design: l.design)).foregroundColor(l.ink2).lineLimit(1)
                    }
                } else if !entry.hasData {
                    EmptyHint(look: l)
                }
                Spacer(minLength: 4)
                HStack {
                    Text("今年 \(entry.day.dayOfYear)日目")
                    Spacer()
                    Text("あと \(entry.day.daysInYear - entry.day.dayOfYear)日")
                }
                .font(.system(size: 9, weight: .medium, design: l.design)).foregroundColor(l.ink2).tracking(1)
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
        }
    }
}

// ---------- ロック画面 ----------

struct LockRect: View {
    let label: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11, weight: .bold)).widgetAccentable()
            Text(text).font(.system(size: 13, weight: .medium)).lineLimit(3).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LockCircle: View {
    let entry: CardEntry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text("\(entry.day.d)").font(.system(size: 22, weight: .bold)).widgetAccentable()
                Text(HK.weekdays[entry.day.weekday]).font(.system(size: 10, weight: .semibold))
            }
        }
    }
}

// ---------- ウィジェット本体 ----------

struct TodayCardView: View {
    @Environment(\.widgetFamily) var family
    let entry: CardEntry

    var cardText: String {
        if let c = entry.card { return c.text.isEmpty ? "写真のカード" : c.text }
        return entry.hasData ? "今日の1枚" : "アプリでカードを作りましょう"
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                LockRect(label: "\(entry.day.m)/\(entry.day.d) \(HK.weekdays[entry.day.weekday])  きょうの1枚", text: cardText).widgetBackground(.clear)
            case .accessoryInline:
                Text(cardText).widgetBackground(.clear)
            case .accessoryCircular:
                LockCircle(entry: entry).widgetBackground(.clear)
            case .systemMedium:
                MediumSheet(entry: entry).widgetBackground(entry.look.paper)
            case .systemLarge:
                LargeSheet(entry: entry).widgetBackground(entry.look.paper)
            default:
                SmallSheet(entry: entry).widgetBackground(entry.look.paper)
            }
        }
        .widgetURL(URL(string: "himekuri://today"))
    }
}

struct MemoryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CardEntry

    var body: some View {
        let l = entry.look
        Group {
            switch family {
            case .accessoryInline:
                Text(entry.memory.map { "\($0.label)：\($0.text)" } ?? "ひとことを書くと、ここに届きます").widgetBackground(.clear)
            case .accessoryRectangular:
                LockRect(label: entry.memory?.label ?? "この日のひとこと", text: entry.memory?.text ?? "書いたひとことが、来週・来月・来年の今日に届きます").widgetBackground(.clear)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Circle().fill(l.accent).frame(width: 6, height: 6)
                        Text(entry.memory?.label ?? "この日のひとこと").font(.system(size: 11, weight: .bold, design: l.design)).foregroundColor(l.accent).tracking(1)
                    }
                    Text(entry.memory?.text ?? "ひとことを書くと、来週・来月・来年の今日にここへ届きます")
                        .font(.system(size: entry.memory == nil ? 12 : 14, weight: .medium, design: l.design)).foregroundColor(entry.memory == nil ? l.ink2 : l.ink)
                        .lineLimit(5).minimumScaleFactor(0.75).lineSpacing(3)
                    Spacer(minLength: 0)
                    Text("\(entry.day.m)月\(entry.day.d)日 \(HK.weekdaysLong[entry.day.weekday])").font(.system(size: 10, weight: .semibold, design: l.design)).foregroundColor(l.ink2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetBackground(l.paper)
            }
        }
        .widgetURL(URL(string: "himekuri://log"))
    }
}

struct TodayCardWidget: Widget {
    let kind = "TodayCard"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayCardView(entry: entry)
        }
        .configurationDisplayName("今日の1枚")
        .description("今日めくれたカードを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct MemoryWidget: Widget {
    let kind = "Memory"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MemoryView(entry: entry)
        }
        .configurationDisplayName("この日のひとこと")
        .description("去年・先月・先週の今日に書いたひとことを表示します。")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct HimekuriWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayCardWidget()
        MemoryWidget()
    }
}
