//
//  MVPlacePreviewCard.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 27/01/26.
//

import SwiftUI

// ✅ Ajuste esperado do seu model:
// struct MVImagem { let asset_thumb: String; let asset_full: String; let descricao: String? }

struct MVPlacePreviewCard: View {
    let point: MVPoint
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                // ✅ Thumbnail / mini carrossel (usa asset_thumb)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)

                    if point.imagens.isEmpty {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    } else if point.imagens.count == 1, let img = point.imagens.first {
                        Image(img.asset_thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        TabView {
                            ForEach(point.imagens.indices, id: \.self) { i in
                                Image(point.imagens[i].asset_thumb)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipped()

                // ✅ Infos
                VStack(alignment: .leading, spacing: 6) {
                    Text(point.titulo)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 2) {

                        Text(point.fonte)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                               Image(systemName: "heart.fill")
                                   .font(.system(size: 12, weight: .semibold))
                                   .foregroundStyle(.red.opacity(0.85))

                               Text("\(point.likesCount)")
                                   .font(.system(size: 13, weight: .semibold))
                                   .foregroundStyle(.secondary)
                           }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white) // ✅ branco
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Fechar") { onClose() }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black.opacity(0.55))
                    .frame(width: 26, height: 26)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            }
            .padding(6)
        }
    }
}

