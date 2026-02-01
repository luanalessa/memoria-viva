//
//  SalvosView.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 31/01/26.
//


import SwiftUI

struct SalvosView: View {

    @State private var events: [SavedEvent] = [
        SavedEvent(
            title: "Festa de São Sebastião",
            location: "Praça da Igreja",
            date: Date(), // ajuste depois
            time: "19:00",
            reminderActive: true
        ),
        SavedEvent(
            title: "Feira Cultural",
            location: "Praça Central",
            date: Date(),
            time: "08:00",
            reminderActive: false
        ),
        SavedEvent(
            title: "Apresentação de Reisado",
            location: "Igreja Matriz",
            date: Date(),
            time: "20:00",
            reminderActive: true
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Meus Eventos")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(events.count) eventos salvos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(events) { event in
                        SavedEventCard(
                            event: event,
                            onToggleReminder: {
                                toggleReminder(event)
                            },
                            onDelete: {
                                delete(event)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func toggleReminder(_ event: SavedEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].reminderActive.toggle()
        }
    }

    private func delete(_ event: SavedEvent) {
        events.removeAll { $0.id == event.id }
    }
}
