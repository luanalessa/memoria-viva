import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    let centerTitle: String
    let cityCenter: CLLocationCoordinate2D

    @State private var showDetailsSheet = false
    @State private var previewPoint: MVPoint? = nil

    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""

    // topo (estilo iFood)
    @State private var currentLocationName = "Itaiçaba – CE"
    @State private var showLocationPicker = false

    // filtros
    @State private var selectedChips: Set<ChipType> = [.memoria, .eventos, .ondeIr]
    @State private var points: [MVPoint] = []

    init(centerTitle: String, cityCenter: CLLocationCoordinate2D) {
        self.centerTitle = centerTitle
        self.cityCenter = cityCenter
        _region = State(initialValue: MKCoordinateRegion(
            center: cityCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ))
    }

    var body: some View {
        MVMapKitView(
            region: $region,
            points: filteredPoints()
        ) { point in
            withAnimation(.spring()) { previewPoint = point }
        }
        .ignoresSafeArea()

        // topo
        .overlay(alignment: .top) {
            VStack(spacing: 12) {

                // header branco estilo iFood
                VStack(spacing: 0) {
                    MVTopAddressHeader(
                        title: currentLocationName,
                        onTap: { showLocationPicker = true }
                    )
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    Divider()
                }
                .background(Color.white)
                .ignoresSafeArea(edges: .top)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // busca do app (histórias/eventos)
                SearchBarFake(text: $searchText)
                    .padding(.horizontal, 16)

                // chips
                HStack(spacing: 10) {
                    Chip(
                        title: "Memória",
                        systemImage: "book",
                        isSelected: selectedChips.contains(.memoria),
                        selectedColor: Color(red: 0.86, green: 0.43, blue: 0.23)
                    ) { toggle(.memoria) }

                    Chip(
                        title: "Eventos",
                        systemImage: "calendar",
                        isSelected: selectedChips.contains(.eventos),
                        selectedColor: Color(red: 0.90, green: 0.70, blue: 0.22)
                    ) { toggle(.eventos) }

                    Chip(
                        title: "Onde ir",
                        systemImage: "storefront",
                        isSelected: selectedChips.contains(.ondeIr),
                        selectedColor: Color(red: 0.30, green: 0.62, blue: 0.39)
                    ) { toggle(.ondeIr) }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
        }

        // card inferior
        .safeAreaInset(edge: .bottom) {
            if let p = previewPoint {
                MVPlacePreviewCard(
                    point: p,
                    onTap: { showDetailsSheet = true },
                    onClose: { withAnimation(.spring()) { previewPoint = nil } }
                )
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 96)
                .padding(.bottom, 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: previewPoint?.id)

        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)

        .onAppear {
            do {
                points = try MVGeoJSONLoader.loadPointsFromBundle(filename: "itaicaba-ceara")
            } catch {
                print("Erro GeoJSON:", error.localizedDescription)
            }
        }

        .sheet(isPresented: $showDetailsSheet) {
            if let p = previewPoint {
                MVPointDetailSheet(point: p, onClose: { showDetailsSheet = false })
            }
        }

        // ✅ mudar endereço + refletir no mapa
        .sheet(isPresented: $showLocationPicker) {
            MVLocationPickerSheet(
                currentLabel: currentLocationName,
                initialRegionCenter: region.center
            ) { chosenTitle, chosenCoordinate in
                // 1) atualiza label
                currentLocationName = chosenTitle

                // 2) fecha sheet primeiro (evita corrida de layout)
                showLocationPicker = false

                // 3) AQUI É O PULO DO GATO:
                //    atribui um NOVO MKCoordinateRegion inteiro (não muta region.center)
                let newRegion = MKCoordinateRegion(
                    center: chosenCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08) // ou region.span se quiser manter zoom atual
                )

                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        region = newRegion
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Toggle
    private func toggle(_ chip: ChipType) {
        if selectedChips.contains(chip) { selectedChips.remove(chip) }
        else { selectedChips.insert(chip) }
    }

    // MARK: - FILTER
    private func filteredPoints() -> [MVPoint] {
        if selectedChips.isEmpty { return [] }
        return points.filter { p in
            guard let chip = chipType(for: p) else { return false }
            return selectedChips.contains(chip)
        }
    }

    private func chipType(for p: MVPoint) -> ChipType? {
        let c = p.categoriaApp.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if c == "memoria" { return .memoria }
        if c == "evento" { return .eventos }
        if c == "onde_ir" || c == "onde ir" { return .ondeIr }
        return nil
    }

    // MARK: - ZOOM (mantido)
    private func zoomIn() {
        region.span.latitudeDelta = max(region.span.latitudeDelta * 0.7, 0.002)
        region.span.longitudeDelta = max(region.span.longitudeDelta * 0.7, 0.002)
    }

    private func zoomOut() {
        region.span.latitudeDelta = min(region.span.latitudeDelta * 1.4, 5.0)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 1.4, 5.0)
    }
}

// MARK: - header topo estilo iFood
private struct MVTopAddressHeader: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FILTER TYPE
enum ChipType: Hashable { case memoria, eventos, ondeIr }

// MARK: - COMPONENTS
private struct SearchBarFake: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Buscar histórias, eventos…", text: $text)
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
        .buttonStyle(.plain)
    }
}

private extension View {
    @ViewBuilder
    func applyDetentsIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([PresentationDetent.medium, PresentationDetent.large])
        } else {
            self
        }
    }
}
