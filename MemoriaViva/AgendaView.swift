//
//  AgendaView 2.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 30/01/26.
//

import SwiftUI


struct AgendaView: View {

    let events: [Event]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Agenda")
                        .font(.largeTitle)
                        .bold()

                    Text("O que está acontecendo em Itaiçaba")
                        .foregroundColor(.gray)
                }

                // Hoje
                Text("🔥 Hoje na cidade")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(events.filter { $0.isToday }) { event in
                            EventCardView(event: event)
                                .frame(width: 260)
                        }
                    }
                }

                // Próximos
                Text("📅 Próximos eventos")
                    .font(.headline)

                VStack(spacing: 16) {
                    ForEach(events.filter { !$0.isToday }) { event in
                        EventCardView(event: event)
                    }
                }
            }
            .padding()
        }
    }
}
