//
//  SavedEventCard.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 31/01/26.
//
import SwiftUI


struct SavedEventCard: View {

    let event: SavedEvent
    let onToggleReminder: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                // Data + hora
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sáb, 27 Jan")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())

                    Text(event.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Ações
                HStack(spacing: 12) {

                    Button(action: onToggleReminder) {
                        Image(systemName: event.reminderActive ? "bell.fill" : "bell.slash")
                            .foregroundColor(event.reminderActive ? .white : .gray)
                            .frame(width: 40, height: 40)
                            .background(
                                event.reminderActive
                                ? Color.orange
                                : Color.gray.opacity(0.2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 40, height: 40)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            // Título e local
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if event.reminderActive {
                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "bell")
                    Text("Lembrete ativo • 1 hora antes")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
