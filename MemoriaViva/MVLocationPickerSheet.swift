//
//  MVLocationPickerSheet.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 30/01/26.
//


import SwiftUI
import MapKit
import CoreLocation

struct MVLocationPickerSheet: View {
    let currentLabel: String
    let initialRegionCenter: CLLocationCoordinate2D
    let onSelect: (_ title: String, _ coordinate: CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addressText: String = ""
    @StateObject private var service = MVLocationSearchService()

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Endereço atual")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(currentLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Campo de busca do endereço
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)

                    TextField("Digite uma cidade, rua, bairro…", text: $addressText)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .onChange(of: addressText) { _, newValue in
                            service.updateQuery(newValue, near: initialRegionCenter)
                        }

                    if !addressText.isEmpty {
                        Button {
                            addressText = ""
                            service.clear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)

                // Resultados
                if service.shouldShowResults {
                    List {
                        ForEach(service.results, id: \.self) { item in
                            Button {
                                service.resolve(item) { coordinate, title in
                                    guard let coordinate else { return }
                                    onSelect(title ?? item.title, coordinate)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .semibold))
                                    if !item.subtitle.isEmpty {
                                        Text(item.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                    Text("Comece digitando para ver sugestões.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Mudar localização")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
