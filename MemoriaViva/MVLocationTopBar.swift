//
//  MVLocationTopBar.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 29/01/26.
//


import SwiftUI

struct MVLocationTopBar: View {
    let locationName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)

                Text(locationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(.plain)
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}
