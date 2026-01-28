import SwiftUI

struct MVPointDetailSheet: View {
    let point: MVPoint
    let onClose: () -> Void
    private let memoriaOrange = Color(red: 0.86, green: 0.43, blue: 0.23)

    @State private var isSaved = false
    @State private var isLiked = false
    @State private var showHours = false

    // ✅ UI-only: estado local do lembrete
    @State private var reminderEnabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // ✅ MÍDIA PRIMEIRO (carrossel) — usa asset_full
                    if !point.imagens.isEmpty {
                        TabView {
                            ForEach(point.imagens.indices, id: \.self) { i in
                                let img = point.imagens[i]
                                Image(img.asset_full)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 250)
                        .padding(.top, 8)
                    }

                    Text(point.titulo)
                        .font(.title2).bold()

                    HStack(spacing: 10) {
                        Text(labelText(for: point))
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(labelColor(for: point))
                            .clipShape(Capsule())

                        Text(point.fonte)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Button { isLiked.toggle() } label: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(isLiked ? .red : .secondary)
                                .font(.system(size: 18, weight: .semibold))
                        }

                        Button { isSaved.toggle() } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(isSaved ? Color(red: 0.86, green: 0.43, blue: 0.23) : .secondary)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }

                    if point.localNome != "-" {
                        Text("📍 \(point.localNome)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    
                    if point.categoriaApp == "onde_ir",
                       let h = point.horario,
                       let lines = h.weekday_text,
                       !lines.isEmpty {

                        VStack(alignment: .leading, spacing: 10) {

                            // 🔹 Cabeçalho (sempre visível)
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showHours.toggle()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)

                                    Text(h.status ?? "Horário")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(
                                            (h.status ?? "").lowercased().contains("fechado")
                                            ? .red
                                            : .green
                                        )

                                    Spacer()

                                    Image(systemName: showHours ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            // 🔹 Conteúdo do dropdown
                            if showHours {
                                VStack(spacing: 8) {
                                    ForEach(lines, id: \.self) { row in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text(dayOnly(row))
                                                .font(.footnote.weight(.semibold))
                                                .frame(width: 110, alignment: .leading)

                                            Text(timeOnly(row))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)

                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.top, 6)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.top, 4)
                    }


                    
                    
                    // ✅ EVENTO: calendário + datas + lembrete
                    if point.categoriaApp == "evento" {
                        VStack(alignment: .leading, spacing: 10) {

                            // Calendário + data
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                Text(eventDateText(point))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }

                            // ✅ Botão lembrete (UI-only)
                            if let days = daysUntilEventStart(point) {
                                HStack(spacing: 10) {
                                    Button {
                                        reminderEnabled.toggle()
                                        // aqui no futuro você agenda/cancela notificação
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: reminderEnabled ? "bell.fill" : "bell")
                                                .font(.system(size: 14, weight: .semibold))

                                            Text(reminderEnabled ? "Lembrete ativado" : "Ativar lembrete")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundStyle(reminderEnabled ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            reminderEnabled
                                            ? Color(red: 0.86, green: 0.43, blue: 0.23)
                                            : Color.black.opacity(0.06)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    // ✅ “faltam X dias”
                                    Text(daysRemainingText(days))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                // ✅ Linha auxiliar (1 dia antes)
                                if reminderEnabled {
                                    Text("Te avisaremos 1 dia antes do evento começar.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                // Sem data exata -> só mostra botão “desabilitado”
                                HStack(spacing: 10) {
                                    Image(systemName: "bell")
                                        .foregroundStyle(.secondary)

                                    Text("Lembrete indisponível (evento sem data exata)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }

                    Divider()

                    Text(point.descricao)
                        .font(.body)

                    let captions = point.imagens.compactMap { img in
                        let d = (img.descricao ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        return d.isEmpty ? nil : d
                    }

                    if point.categoriaApp == "onde_ir",
                       let c = point.contato,
                       (hasText(c.whatsapp) || hasText(c.instagram)) {

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contato")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {

                                // ✅ WhatsApp
                                if let w = c.whatsapp, hasText(w),
                                   let url = whatsappURL(w) {
                                    Link(destination: url) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "message.fill")
                                            Text("WhatsApp")
                                        }
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(memoriaOrange)
                                        .clipShape(Capsule())
                                    }
                                }

                                // ✅ Instagram
                                if let ig = c.instagram, hasText(ig),
                                   let url = instagramURL(ig) {
                                    Link(destination: url) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                            Text("@\(ig)")
                                        }
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(memoriaOrange)
                                        .clipShape(Capsule())
                                    }
                                }

                                Spacer()
                            }
                        }
                    }

                    
                    if !captions.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sobre as imagens")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(captions.indices, id: \.self) { i in
                                Text("• \(captions[i])")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black.opacity(0.55))
                            .frame(width: 32, height: 32)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Datas de evento
    private func dayOnly(_ s: String) -> String {
        s.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? s
    }

    private func timeOnly(_ s: String) -> String {
        let parts = s.components(separatedBy: ":")
        guard parts.count >= 2 else { return "" }
        return parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hasText(_ s: String?) -> Bool {
        !(s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func whatsappURL(_ raw: String) -> URL? {
        // aceita "+55...", "55...", "(88) 9...."
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://wa.me/\(digits)")
    }

    private func instagramURL(_ raw: String) -> URL? {
        let user = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !user.isEmpty else { return nil }
        return URL(string: "https://instagram.com/\(user)")
    }

    
    private func eventDateText(_ p: MVPoint) -> String {
        // se tiver data_exata_inicio, mostra dd/MM/yyyy
        if let start = parseYMD(p.dataExataInicio) {
            return formatBR(start)
        }
        // fallback
        return "Data a definir"
    }

    private func daysUntilEventStart(_ p: MVPoint) -> Int? {
        guard let start = parseYMD(p.dataExataInicio) else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let startDay = Calendar.current.startOfDay(for: start)
        let diff = Calendar.current.dateComponents([.day], from: today, to: startDay).day
        return diff
    }

    private func daysRemainingText(_ days: Int) -> String {
        if days < 0 { return "Já aconteceu" }
        if days == 0 { return "É hoje" }
        if days == 1 { return "Falta 1 dia" }
        return "Faltam \(days) dias"
    }

    private func parseYMD(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: s)
    }

    private func formatBR(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy"
        return df.string(from: d)
    }
}

private func labelColor(for p: MVPoint) -> Color {
    switch p.categoriaApp.lowercased() {
    case "memoria":
        return Color(red: 0.86, green: 0.43, blue: 0.23) // laranja (sua cor do chip)
    case "evento":
        return Color(red: 0.90, green: 0.70, blue: 0.22) // mostarda
    case "onde_ir", "onde ir":
        return Color(red: 0.30, green: 0.62, blue: 0.39) // verde
    default:
        return Color.black.opacity(0.30)
    }
}

private func labelText(for p: MVPoint) -> String {
    switch p.categoriaApp.lowercased() {
    case "memoria": return "Memória"
    case "evento": return "Evento"
    case "onde_ir", "onde ir": return "Onde ir"
    default: return p.tipo
    }
}
