import Foundation

// ---------------------------------------------------------------
// index.html の syncWidget() が App Group に書く JSON を読み、
// 「その日のカード」を JS と同じ手順で選ぶ。
// JS 側: poolFor / baseIndex / basePick / pickFor（index.html）
// ---------------------------------------------------------------

struct HKCard: Decodable {
    let id: String
    let text: String
    let sub: String?
    let kind: String?      // any / date / wday
    let date: String?      // "MM-DD"（kind == date）
    let wdays: [Int]?      // 0=日 … 6=土（kind == wday）
    let order: Double?
    let img: Bool?
}

struct HKSettings: Decodable {
    let mode: String?      // random / order
    let paper: String?
    let font: String?
    let accent: String?
    let seed: String?
}

struct HKData: Decodable {
    let cards: [HKCard]
    let notes: [String: String]?
    let overrides: [String: String]?
    let settings: HKSettings?
}

/// 端末のカレンダーで見た「年月日」
struct HKDay {
    let y: Int, m: Int, d: Int
    init(_ date: Date) {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        y = c.year ?? 1970; m = c.month ?? 1; d = c.day ?? 1
    }
    var str: String { String(format: "%04d-%02d-%02d", y, m, d) }
    var mmdd: String { String(format: "%02d-%02d", m, d) }
    var days: Int { HK.daysFromCivil(y, m, d) }
    var weekday: Int { ((days + 4) % 7 + 7) % 7 }
    var dayOfYear: Int { days - HK.daysFromCivil(y, 1, 1) + 1 }
    var daysInYear: Int { HK.daysFromCivil(y, 12, 31) - HK.daysFromCivil(y, 1, 1) + 1 }
}

enum HK {
    static let groupId = "group.work.ltv.himekuri"
    static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    static let weekdaysLong = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]

    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId)
    }

    static func load() -> HKData? {
        guard let url = container?.appendingPathComponent("himekuri.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(HKData.self, from: data)
    }

    static func imageURL(_ id: String) -> URL? {
        container?.appendingPathComponent("img_\(id).jpg")
    }

    /// 1970-01-01 からの日数。JS の daysFromCivil と同じ式
    static func daysFromCivil(_ y0: Int, _ m: Int, _ d: Int) -> Int {
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = m > 2 ? m - 3 : m + 9
        let doy = (153 * mp + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }

    /// FNV-1a 32bit。JS の hash() と同じ
    static func fnv(_ s: String) -> UInt32 {
        var h: UInt32 = 2166136261
        for u in s.unicodeScalars { h ^= u.value; h = h &* 16777619 }
        return h
    }

    static func pool(for day: HKDay, cards: [HKCard]) -> [HKCard] {
        var pool = cards.filter { $0.kind == "date" && $0.date == day.mmdd }
        if pool.isEmpty { pool = cards.filter { $0.kind == "wday" && ($0.wdays ?? []).contains(day.weekday) } }
        if pool.isEmpty { pool = cards.filter { ($0.kind ?? "any") == "any" } }
        if pool.isEmpty { pool = cards }
        return pool.sorted { a, b in
            let oa = a.order ?? 0, ob = b.order ?? 0
            if oa != ob { return oa < ob }
            return a.id < b.id
        }
    }

    static func baseIndex(day: HKDay, n: Int, settings: HKSettings?) -> Int {
        if n <= 1 { return 0 }
        if settings?.mode == "order" { return ((day.days % n) + n) % n }
        return Int(fnv((settings?.seed ?? "") + "|" + day.str) % UInt32(n))
    }

    static func basePick(day: HKDay, data: HKData) -> HKCard? {
        let p = pool(for: day, cards: data.cards)
        if p.isEmpty { return nil }
        return p[baseIndex(day: day, n: p.count, settings: data.settings)]
    }

    /// その日のカード。手動でめくり直した日（overrides）はそれを優先
    static func pick(for date: Date, data: HKData) -> HKCard? {
        let day = HKDay(date)
        if let ov = data.overrides?[day.str], let c = data.cards.first(where: { $0.id == ov }) { return c }
        let p = pool(for: day, cards: data.cards)
        if p.isEmpty { return nil }
        let n = p.count
        var i = baseIndex(day: day, n: n, settings: data.settings)
        if n > 1,
           let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date),
           let prev = basePick(day: HKDay(prevDate), data: data),
           prev.id == p[i].id {
            i = (i + 1) % n
        }
        return p[i]
    }

    /// 去年の今日 → N年前の今日 → 先月の今日 → 先週の今日 → きのう の順で、書いてあるものを返す
    static func memory(for date: Date, data: HKData) -> (label: String, text: String)? {
        guard let notes = data.notes, !notes.isEmpty else { return nil }
        let cal = Calendar.current
        let dom = cal.component(.day, from: date)
        func note(_ d: Date?) -> String? {
            guard let d = d, cal.component(.day, from: d) == dom, let t = notes[HKDay(d).str], !t.isEmpty else { return nil }
            return t
        }
        for k in 1...10 {
            if let t = note(cal.date(byAdding: .year, value: -k, to: date)) { return (k == 1 ? "去年の今日" : "\(k)年前の今日", t) }
        }
        if let t = note(cal.date(byAdding: .month, value: -1, to: date)) { return ("先月の今日", t) }
        if let d = cal.date(byAdding: .day, value: -7, to: date), let t = notes[HKDay(d).str], !t.isEmpty { return ("先週の今日", t) }
        if let d = cal.date(byAdding: .day, value: -1, to: date), let t = notes[HKDay(d).str], !t.isEmpty { return ("きのう", t) }
        return nil
    }
}
