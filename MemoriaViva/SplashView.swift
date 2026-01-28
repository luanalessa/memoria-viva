import SwiftUI
import CoreLocation

let itaicabaCenter = CLLocationCoordinate2D(
    latitude: -4.6703,
    longitude: -37.8402
)

struct SplashView: View {
    @StateObject private var locationManager = LocationManager()
    private let geocoder = CLGeocoder()

    @State private var showAddressSearch = false
    @State private var goToMap = false

    @State private var selectedAddressText: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil

    @State private var isResolvingCity = false
    @State private var errorMessage: String? = nil
    @State private var didResolveOnce = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer()

                    Image("memoriaVivaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("Memória Viva")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.8))

                    Text("Descubra histórias, eventos e a\ncultura viva da sua cidade")
                        .font(.system(size: 22, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black.opacity(0.45))
                        .padding(.top, 6)

                    Button {
                        showAddressSearch = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.green)

                            Text(buttonTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.black.opacity(0.65))
                                .lineLimit(1)

                            if isResolvingCity {
                                ProgressView().scaleEffect(0.9)
                            } else {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.black.opacity(0.35))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(.white.opacity(0.75)))
                    }
                    .padding(.top, 10)
                    .sheet(isPresented: $showAddressSearch) {
                        AddressSearchView(
                            initialQuery: selectedAddressText,
                            onSelect: { result in
                                selectedAddressText = result.displayName
                                selectedCoordinate = result.coordinate
                                errorMessage = nil
                                showAddressSearch = false
                            },
                            onCancel: {
                                showAddressSearch = false
                            }
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 22)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    Button {
                        guard canProceed else { return }
                        goToMap = true
                    } label: {
                        HStack {
                            Text("Explorar o mapa")
                                .font(.system(size: 22, weight: .bold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.91, green: 0.52, blue: 0.28),
                                    Color(red: 0.86, green: 0.43, blue: 0.23)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .opacity(canProceed ? 1.0 : 0.45)
                    }
                    .disabled(!canProceed)
                    .padding(.horizontal, 22)

                    Spacer(minLength: 30)
                }
                .navigationDestination(isPresented: $goToMap) {
                    if let coord = selectedCoordinate {
                        RootTabView(centerTitle: selectedAddressText, cityCenter: coord)
                    } else {
                        Text("Selecione uma cidade para continuar.")
                    }
                }

            }
            .onAppear {
                // Ao abrir o app, pede localização
                locationManager.requestPermission()
            }
            .onChange(of: locationManager.authorization) { _, status in
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    locationManager.startUpdates()
                case .denied, .restricted:
                    if selectedCoordinate == nil {
                        errorMessage = "Para continuar, digite um endereço válido."
                        showAddressSearch = true
                    }
                default:
                    break
                }
            }
            .onReceive(locationManager.$userLocation) { coord in
                guard let coord else { return }
                guard !didResolveOnce else { return }

                didResolveOnce = true
                resolveCityFromCoordinate(coord)
            }
        }
    }

    private var canProceed: Bool {
        selectedCoordinate != nil &&
        !selectedAddressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var buttonTitle: String {
        if canProceed { return selectedAddressText }
        if locationManager.authorization == .denied || locationManager.authorization == .restricted {
            return "Digite sua cidade"
        }
        return "Usar minha localização"
    }

    private func resolveCityFromCoordinate(_ coord: CLLocationCoordinate2D) {
        isResolvingCity = true
        errorMessage = nil

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                self.isResolvingCity = false

                guard error == nil, let pm = placemarks?.first else {
                    self.errorMessage = "Não consegui identificar sua cidade. Digite um endereço."
                    self.showAddressSearch = true
                    return
                }

                let city = pm.locality ?? pm.subAdministrativeArea
                let state = pm.administrativeArea

                if let city, let state, !city.isEmpty, !state.isEmpty {
                    self.selectedAddressText = "\(city) – \(state)"
                    self.selectedCoordinate = coord
                    return
                }

                if let city, !city.isEmpty {
                    self.selectedAddressText = city
                    self.selectedCoordinate = coord
                    return
                }

                self.errorMessage = "Não consegui identificar sua cidade. Digite um endereço."
                self.showAddressSearch = true
            }
        }
    }
}
