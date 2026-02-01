import SwiftUI

struct EventCard: View {
    let event: MVEvent
    let onToggleReminder: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            topRow

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 22, weight: .bold))

                Text(event.place)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 17))
            }

            Divider().opacity(0.25)

            bottomRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }

    private var topRow: some View {
        HStack(alignment: .center) {
            datePill

            Spacer()

            Text(timeText(event.startAt))
                .foregroundStyle(.secondary)
                .font(.system(size: 17))

            Spacer(minLength: 10)

            HStack(spacing: 10) {
                reminderButton
                deleteButton
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell")
                .foregroundStyle(.secondary)

            if event.reminderEnabled {
                Text("Lembrete ativo • \(event.reminderMinutesBefore) hora antes")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
            } else {
                Text("Lembrete desativado")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
            }

            Spacer()
        }
    }

    private var datePill: some View {
        Text(datePillText(event.startAt))
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.orange.opacity(0.15))
            )
            .foregroundStyle(Color.orange)
    }

    private var reminderButton: some View {
        Button(action: onToggleReminder) {
            Image(systemName: event.reminderEnabled ? "bell" : "bell.slash")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(event.reminderEnabled ? Color.orange.opacity(0.9) : Color(.systemGray5))
                )
                .foregroundStyle(event.reminderEnabled ? Color.white : Color(.systemGray))
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                )
                .foregroundStyle(Color.red)
        }
        .buttonStyle(.plain)
    }

    private func datePillText(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "EEE, dd MMM"
        // Ex: "sáb., 27 jan" -> deixa com inicial maiúscula e sem ponto se quiser
        return df.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
    }

    private func timeText(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
