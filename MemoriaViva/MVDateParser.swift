import Foundation

enum MVDateParser {

    // ✅ campos mais comuns que você pode ter no GeoJSON
    // ajuste essa lista conforme seu JSON
    private static let candidateKeys = [
        "data_inicio", "dataInicio", "inicio", "start_date", "startDate",
        "data", "date", "dia",
        "data_fim", "dataFim", "fim", "end_date", "endDate"
    ]

    static func extractEventDate(from point: Any) -> Date? {
        // Tenta pegar por KVC (funciona se MVPoint tiver essas propriedades opcionais)
        // Se MVPoint não tiver, você deve adicionar esses campos no model e decodificar do GeoJSON.
        for key in candidateKeys {
            if let s = (point as AnyObject).value(forKey: key) as? String,
               let d = parse(s) {
                return d
            }
        }

        // fallback: tenta achar uma data dentro da descrição (se tiver)
        if let desc = (point as AnyObject).value(forKey: "descricao") as? String {
            if let d = extractDateFromText(desc) { return d }
        }

        return nil
    }

    static func parse(_ raw: String) -> Date? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        // 1) ISO 8601 (2026-01-30 ou 2026-01-30T19:00:00Z)
        if let d = iso8601Date(s) { return d }

        // 2) BR dd/MM/yyyy (30/01/2026)
        if let d = brDate(s) { return d }

        // 3) dd/MM/yyyy HH:mm
        if let d = brDateTime(s) { return d }

        return nil
    }

    static func displayDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "EEE, dd/MM • HH:mm"
        return f.string(from: date)
    }

    private static func iso8601Date(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }

        // tenta ISO sem fractional
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let d = iso2.date(from: s) { return d }

        // tenta YYYY-MM-DD (sem hora)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private static func brDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeZone = .current
        f.dateFormat = "dd/MM/yyyy"
        return f.date(from: s)
    }

    private static func brDateTime(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeZone = .current
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f.date(from: s)
    }

    private static func extractDateFromText(_ text: String) -> Date? {
        // pega algo tipo 05/09/2025 ou 2025-09-05
        let patterns = [
            #"(\d{2}/\d{2}/\d{4})"#,
            #"(\d{4}-\d{2}-\d{2})"#
        ]

        for p in patterns {
            if let r = text.range(of: p, options: .regularExpression) {
                let match = String(text[r])
                return parse(match)
            }
        }
        return nil
    }
}
