import SwiftUI
import CoreLocation

struct AddressResult: Identifiable {
    let id = UUID()
    let displayName: String
    let coordinate: CLLocationCoordinate2D
}

struct AddressSearchView: View {
    let initialQuery: String
    let onSelect: (AddressResult) -> Void
    let onCancel: () -> Void

    @State private var query: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var results: [AddressResult] = []

    private let geocoder = CLGeocoder()

    init(initialQuery: String, onSelect: @escaping (AddressResult) -> Void, onCancel: @escaping () -> Void) {
        self.initialQuery = initialQuery
        self.onSelect = onSelect
        self.onCancel = onCancel
        _query = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Digite um endereço (ex: Centro, Itaiçaba)", text: $query)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit { search() }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            results = []
                            errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 10)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 10)
                }

                List(results) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            Text("\(item.coordinate.latitude), \(item.coordinate.longitude)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Escolher cidade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Buscar") { search() }
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }

    private func search() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        errorMessage = nil
        results = []
        isLoading = true

        geocoder.cancelGeocode()

        geocoder.geocodeAddressString(q) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error as NSError? {
                    if error.code == CLError.Code.geocodeFoundNoResult.rawValue {
                        self.errorMessage = "Endereço não encontrado. Tente ser mais específico."
                    } else if error.code == CLError.Code.geocodeCanceled.rawValue {
                        // ignore
                    } else {
                        self.errorMessage = "Falha ao buscar. Tente novamente."
                    }
                    return
                }

                let items = (placemarks ?? []).compactMap { pm -> AddressResult? in
                    guard let loc = pm.location?.coordinate else { return nil }

                    let city = pm.locality ?? pm.subAdministrativeArea
                    let state = pm.administrativeArea

                    // Preferimos "Cidade – UF" quando disponível
                    let display: String
                    if let city, let state, !city.isEmpty, !state.isEmpty {
                        display = "\(city) – \(state)"
                    } else {
                        let nameParts = [pm.name, pm.locality, pm.administrativeArea, pm.country]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                        display = nameParts.isEmpty ? q : nameParts.joined(separator: ", ")
                    }

                    return AddressResult(displayName: display, coordinate: loc)
                }

                self.results = Array(items.prefix(10))
                if self.results.isEmpty {
                    self.errorMessage = "Endereço não encontrado. Tente ser mais específico."
                }
            }
        }
    }
}
