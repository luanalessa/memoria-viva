//
//  MVPointDetailSheet.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 25/01/26.
//


import SwiftUI

struct MVPointDetailSheet: View {
    let point: MVPoint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(point.titulo)
                    .font(.title2).bold()

                HStack {
                    Text(point.tipo)
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())

                    Text(point.categoria)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                if point.localNome != "-" {
                    Text("📍 \(point.localNome)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(point.descricao)
                    .font(.body)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Fonte")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(point.fonte)
                        .font(.footnote)
                }

                if !point.midia.isEmpty {
                    Divider()
                    Text("Mídia: \(point.midia.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .presentationDetents([.medium, .large])
    }
}
