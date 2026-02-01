import SwiftUI
import MapKit
import CoreLocation

// MARK: - MAP VIEW
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

    // ✅ push (não modal)
    @State private var goToSubmit = false

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

        // ✅ botão flutuante "+" (push)
        .overlay(alignment: .bottomTrailing) {
            ZStack {
                // NavigationLink invisível
                NavigationLink(isActive: $goToSubmit) {
                    MVSubmitContentView()
                } label: {
                    EmptyView()
                }

                MVAddContentButton {
                    goToSubmit = true
                }
                .padding(.trailing, 18)
                .padding(.bottom, 96)
            }
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
                currentLocationName = chosenTitle
                showLocationPicker = false

                let newRegion = MKCoordinateRegion(
                    center: chosenCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
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
}

// MARK: - Floating "+"
private struct MVAddContentButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(Color(red: 0.86, green: 0.43, blue: 0.23))
                )
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        }
        .accessibilityLabel("Enviar conteúdo")
        .accessibilityHint("Adicione uma memória, evento ou lugar")
        .buttonStyle(.plain)
    }
}

// MARK: - Tela Enviar conteúdo (push, não modal)
struct MVSubmitContentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: MVSubmitType = .memoria
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var source: String = ""
    @State private var locationLabel: String = "Marcar no mapa"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                Text("Contribua com a memória da cidade")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                Text("Tipo de conteúdo")
                    .font(.system(size: 17, weight: .semibold))

                // ✅ 3 opções na MESMA LINHA, quadradas
                HStack(spacing: 12) {
                    MVTypeSquare(
                        title: "Memória",
                        subtitle: "História, lenda",
                        systemImage: "book",
                        isSelected: selectedType == .memoria,
                        selectedColor: Color(red: 0.86, green: 0.43, blue: 0.23)
                    ) { selectedType = .memoria }

                    MVTypeSquare(
                        title: "Evento",
                        subtitle: "Festa, feira",
                        systemImage: "calendar",
                        isSelected: selectedType == .evento,
                        selectedColor: Color(red: 0.90, green: 0.70, blue: 0.22)
                    ) { selectedType = .evento }

                    MVTypeSquare(
                        title: "Onde ir",
                        subtitle: "Lugares",
                        systemImage: "storefront",
                        isSelected: selectedType == .ondeIr,
                        selectedColor: Color(red: 0.30, green: 0.62, blue: 0.39)
                    ) { selectedType = .ondeIr }
                }

                Text("Título")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 6)

                MVField(text: $title, placeholder: "Ex: A história da Igreja Matriz")

                Text("Descrição")
                    .font(.system(size: 17, weight: .semibold))

                MVTextArea(text: $description, placeholder: "Conte a história ou descreva o evento...")

                Text("Mídia (opcional)")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 6)

                HStack(spacing: 12) {
                    MVMediaButton(title: "Foto", systemImage: "photo") { /* TODO */ }
                    MVMediaButton(title: "Áudio", systemImage: "mic") { /* TODO */ }
                }

                Text("Localização")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 6)

                MVLocationButton(title: locationLabel) {
                    // TODO: abrir marcação no mapa
                }

                Text("Fonte do conteúdo")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 6)

                MVField(text: $source, placeholder: "Ex: Seu Antônio, morador há 80 anos")

                MVInfoBanner(text: "Todo conteúdo passa por curadoria antes de ser publicado, garantindo a qualidade e veracidade das informações.")
                    .padding(.top, 4)

                // ✅ botão ativo
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                        Text("Enviar para curadoria")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 0.91, green: 0.75, blue: 0.69))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.top, 6)
                .padding(.bottom, 28)
                .disabled(false)
                .opacity(1)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(Color(white: 0.98))
        .navigationTitle("Enviar conteúdo")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}

enum MVSubmitType: String { case memoria, evento, ondeIr }

// MARK: - Type square card
private struct MVTypeSquare: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let selectedColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.20) : Color.black.opacity(0.04))
                        .frame(width: 40, height: 40)

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary.opacity(0.85))
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? selectedColor : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(isSelected ? 0 : 0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

private struct MVField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(white: 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .font(.system(size: 16))
    }
}

private struct MVTextArea: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(minHeight: 160)
                .font(.system(size: 16))
        }
        .background(Color(white: 0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MVMediaButton: View {
    let title: String
    let systemImage: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MVLocationButton: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MVInfoBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.orange)

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.primary.opacity(0.75))

            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.98, green: 0.94, blue: 0.86))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
        )
    }
}

