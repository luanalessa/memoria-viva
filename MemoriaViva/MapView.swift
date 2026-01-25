import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    let centerTitle: String
    let cityCenter: CLLocationCoordinate2D

    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""

    // ✅ multi seleção
    @State private var selectedChips: Set<ChipType> = []

    // ✅ pontos do GeoJSON + seleção
    @State private var points: [MVPoint] = []
    @State private var selectedPoint: MVPoint? = nil

    init(centerTitle: String, cityCenter: CLLocationCoordinate2D) {
        self.centerTitle = centerTitle
        self.cityCenter = cityCenter
        _region = State(initialValue: MKCoordinateRegion(
            center: cityCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {

            // MAPA (MapKit via UIViewRepresentable)
            MVMapKitView(
                region: $region,
                points: filteredPoints()
            ) { point in
                selectedPoint = point
            }
            .ignoresSafeArea()

            // UI SUPERIOR (BUSCA + CHIPS)
            VStack(spacing: 12) {
                SearchBarFake(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                HStack(spacing: 10) {
                    Chip(
                        title: "Memória",
                        systemImage: "book",
                        isSelected: selectedChips.contains(.memoria),
                        selectedColor: Color(red: 0.86, green: 0.43, blue: 0.23) // laranja
                    ) {
                        toggle(.memoria)
                    }

                    Chip(
                        title: "Eventos",
                        systemImage: "calendar",
                        isSelected: selectedChips.contains(.eventos),
                        selectedColor: Color(red: 0.90, green: 0.70, blue: 0.22) // mostarda
                    ) {
                        toggle(.eventos)
                    }

                    Chip(
                        title: "Onde ir",
                        systemImage: "storefront",
                        isSelected: selectedChips.contains(.ondeIr),
                        selectedColor: Color(red: 0.30, green: 0.62, blue: 0.39) // verde
                    ) {
                        toggle(.ondeIr)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }

            // ZOOM + / - (LADO ESQUERDO)
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    Button { zoomIn() } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Button { zoomOut() } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                }
                .padding(.leading, 16)
                .padding(.bottom, 90) // acima da tab bar
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // BOTÃO +
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        // ação futura
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.86, green: 0.43, blue: 0.23))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 10)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 90)
                }
            }
        }
        .navigationTitle(centerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            do {
                // ✅ nome do arquivo sem extensão: memoria-viva-itaiçaba.geojson
                points = try MVGeoJSONLoader.loadPointsFromBundle(filename: "itaicaba-ceara")
            } catch {
                print("Erro GeoJSON:", error.localizedDescription)
            }
        }
        .sheet(item: $selectedPoint) { p in
            MVPointDetailSheet(point: p)
        }
    }

    // MARK: - Multi-select toggle

    private func toggle(_ chip: ChipType) {
        if selectedChips.contains(chip) {
            selectedChips.remove(chip)
        } else {
            selectedChips.insert(chip)
        }
    }

    // MARK: - FILTER

    private func filteredPoints() -> [MVPoint] {
        // Se nada selecionado, mostra tudo
        if selectedChips.isEmpty { return points }

        return points.filter { p in
            // GeoJSON atual só tem Memória
            if selectedChips.contains(.memoria) {
                let t = p.tipo.lowercased()
                return t.contains("memória") || t.contains("memoria")
            }
            // Eventos/Onde ir entram quando você tiver esses dados no JSON/API
            return false
        }
    }

    // MARK: - ZOOM HELPERS

    private func zoomIn() {
        region.span.latitudeDelta = max(region.span.latitudeDelta * 0.7, 0.002)
        region.span.longitudeDelta = max(region.span.longitudeDelta * 0.7, 0.002)
    }

    private func zoomOut() {
        region.span.latitudeDelta = min(region.span.latitudeDelta * 1.4, 5.0)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 1.4, 5.0)
    }
}

// MARK: - FILTER TYPE

enum ChipType: Hashable {
    case memoria
    case eventos
    case ondeIr
}

// MARK: - COMPONENTS

private struct SearchBarFake: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Buscar lugares, histórias…", text: $text)
                .disabled(true)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct Chip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? selectedColor : .white.opacity(0.75))
            .foregroundStyle(isSelected ? .white : Color.black.opacity(0.60))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
