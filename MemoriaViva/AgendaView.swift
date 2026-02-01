//
//  AgendaView.swift
//  MemoriaViva
//

import SwiftUI

struct AgendaView: View {
    let points: [MVPoint]

    @State private var savedIds: Set<String> = []

    private var eventPoints: [MVPoint] {
        points.filter { $0.categoriaApp == "evento" }
    }

    private var todayEvents: [MVPoint] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        return eventPoints
            .filter { p in
                guard let d = p.startDate else { return false }
                return d >= start && d < end
            }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    private var nextEvents: [MVPoint] {
        let start = Calendar.current.startOfDay(for: Date())

        return eventPoints
            .filter { p in
                guard let d = p.startDate else { return false }
                return d >= start && !Calendar.current.isDateInToday(d)
            }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                header

                // Hoje
                sectionTitle(icon: "flame.fill", iconBg: Color.orange.opacity(0.18), title: "Hoje na cidade")

                if todayEvents.isEmpty {
                    emptyState("Nada marcado para hoje.")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(todayEvents, id: \.id) { p in
                                AgendaCard(
                                    point: p,
                                    isSaved: savedIds.contains(p.id),
                                    onToggleSave: { toggleSave(p.id) }
                                )
                                .frame(width: 275, height: 175)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Próximos
                sectionTitle(icon: "calendar", iconBg: Color.yellow.opacity(0.22), title: "Próximos eventos")

                if nextEvents.isEmpty {
                    emptyState("Nenhum evento futuro encontrado.")
                } else {
                    VStack(spacing: 14) {
                        ForEach(nextEvents, id: \.id) { p in
                            AgendaWideCard(
                                point: p,
                                isSaved: savedIds.contains(p.id),
                                onToggleSave: { toggleSave(p.id) }
                            )
                            .frame(height: 170)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 18)
            }
            .padding(.top, 18)
        }
        .background(.white)
    }

    // MARK: - UI pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Agenda")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)

            Text("O que está acontecendo em Itaiçaba")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black.opacity(0.55))
        }
        .padding(.horizontal, 20)
    }

    private func sectionTitle(icon: String, iconBg: Color, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(iconBg).frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange.opacity(0.9))
            }

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.black.opacity(0.55))
            .padding(.horizontal, 20)
    }

    private func toggleSave(_ id: String) {
        if savedIds.contains(id) { savedIds.remove(id) }
        else { savedIds.insert(id) }
    }
}

// MARK: - Cards

private struct AgendaCard: View {
    let point: MVPoint
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.92, green: 0.88, blue: 0.80))
                        .frame(height: 92)

                    DatePill(date: point.startDate ?? Date())
                        .padding(14)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(point.titulo)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.9))
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.45))
                            Text(point.localNome)
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.45))
                                .lineLimit(1)
                        }

                        Spacer()

                        if let time = point.timeText, !time.isEmpty {
                            Text(time)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.orange.opacity(0.85))
                        }
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Button(action: onToggleSave) {
                ZStack {
                    Circle().fill(.white).frame(width: 34, height: 34)
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.65))
                }
            }
            .padding(12)
        }
    }
}

private struct AgendaWideCard: View {
    let point: MVPoint
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.92, green: 0.88, blue: 0.80))
                        .frame(height: 92)

                    DatePill(date: point.startDate ?? Date())
                        .padding(14)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(point.titulo)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.9))
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.45))
                            Text(point.localNome)
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.45))
                                .lineLimit(1)
                        }

                        Spacer()

                        if let time = point.timeText, !time.isEmpty {
                            Text(time)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.orange.opacity(0.85))
                        }
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Button(action: onToggleSave) {
                ZStack {
                    Circle().fill(.white).frame(width: 34, height: 34)
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black.opacity(0.65))
                }
            }
            .padding(12)
        }
    }
}

private struct DatePill: View {
    let date: Date

    var body: some View {
        VStack(spacing: 2) {
            Text(monthAbbrev(date).uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black.opacity(0.5))

            Text(dayNumber(date))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black.opacity(0.85))
        }
        .frame(width: 56, height: 56)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX") // "JAN"
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "dd"
        return f.string(from: date)
    }
}

// MARK: - MVPoint helpers (data parsing)

private extension MVPoint {
    var startDate: Date? {
        if let iso = dataExataInicio ?? dataInicio,
           let d = Self.parseISO(iso) {
            return d
        }
        return nil
    }

    var timeText: String? {
        guard let t = dataTexto?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        if Self.looksLikeHour(t) { return t }
        return nil
    }

    static func parseISO(_ value: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: value)
    }

    static func looksLikeHour(_ s: String) -> Bool {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0...23).contains(h), (0...59).contains(m) else { return false }
        return true
    }
}

