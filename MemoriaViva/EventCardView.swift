//
//  EventCardView.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 30/01/26.
//
import SwiftUI


struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                VStack {
                    Text(event.date, format: .dateTime.month(.abbreviated))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(event.date, format: .dateTime.day())
                        .font(.title3)
                        .bold()
                }
                .frame(width: 52, height: 52)
                .background(Color.white)
                .cornerRadius(12)

                Spacer()

                Image(systemName: "bookmark")
                    .foregroundColor(.gray)
            }

            Text(event.title)
                .font(.headline)

            HStack {
                Image(systemName: "location")
                Text(event.location)
                Spacer()
                Text(event.time)
                    .foregroundColor(.orange)
                    .bold()
            }
            .font(.caption)
            .foregroundColor(.gray)

        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color("CardTop"), Color("CardBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
    }
}
