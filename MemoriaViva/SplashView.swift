import SwiftUI
import CoreLocation
import MapKit

let itaicabaCenter = CLLocationCoordinate2D(latitude: -4.6703, longitude: -37.8402)

struct SplashView: View {
    @StateObject private var locationManager = LocationManager()
    private let geocoder = CLGeocoder()

    @State private var goToMap = false

    @State private var selectedAddressText: String = "Procurando sua cidade…"
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var didResolveOnce = false

    // ✅ mapa no fundo
    @State private var mapRegion = MKCoordinateRegion(
        center: itaicabaCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    // animação
    @State private var isAnimating = false
    @State private var shimmer = false

#if DEBUG
    private let forceFixedLocationForTests = true
#else
    private let forceFixedLocationForTests = false
#endif

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ MAPA REAL AO FUNDO (não muda o resto da tela)
                LiveMapBackground(region: $mapRegion)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    VStack(spacing: 6) {
                        Text("Memória Viva")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.85))

                        Text("Descobrindo histórias perto de você…")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.55))
                    }
                    .padding(.top, 20)

                    Spacer()

                    ZStack {
                        // pin no centro absoluto
                        ZStack {
                            PinRings(isAnimating: isAnimating)
                            AnimatedPinLogo(isAnimating: isAnimating)
                        }

                        VStack {
                            Spacer()
                            LoadingPills() // loader logo abaixo do pin
                                .padding(.bottom, 60)
                        }
                    }


                    Spacer()
                }
                .padding(.horizontal, 22)
            }
            .navigationDestination(isPresented: $goToMap) {
                let coord = selectedCoordinate ?? itaicabaCenter
                let title = (selectedAddressText.isEmpty || selectedAddressText.contains("Procurando"))
                    ? "Itaiçaba – CE"
                    : selectedAddressText
                RootTabView(centerTitle: title, cityCenter: coord)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) { isAnimating = true }
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    shimmer = true
                }

                locationManager.requestPermission()

                if forceFixedLocationForTests {
                    selectedCoordinate = itaicabaCenter
                    selectedAddressText = "Itaiçaba – CE"
                    didResolveOnce = true
                    mapRegion.center = itaicabaCenter
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if selectedCoordinate == nil {
                        selectedCoordinate = itaicabaCenter
                        selectedAddressText = "Itaiçaba – CE"
                        mapRegion.center = itaicabaCenter
                    }
                    goToMap = true
                }
            }
            .onChange(of: locationManager.authorization) { _, status in
                if forceFixedLocationForTests { return }

                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    locationManager.startUpdates()
                default:
                    break
                }
            }
            .onReceive(locationManager.$userLocation) { coord in
                if forceFixedLocationForTests { return }
                guard let coord else { return }
                guard !didResolveOnce else { return }

                didResolveOnce = true
                selectedCoordinate = coord

                // ✅ mapa no fundo acompanha a localização
                withAnimation(.easeInOut(duration: 0.6)) {
                    mapRegion.center = coord
                }

                resolveCityFromCoordinate(coord)
            }
        }
    }

    private func resolveCityFromCoordinate(_ coord: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                guard error == nil, let pm = placemarks?.first else {
                    self.selectedAddressText = "Sua localização"
                    return
                }

                let city = pm.locality ?? pm.subAdministrativeArea
                let state = pm.administrativeArea

                if let city, let state, !city.isEmpty, !state.isEmpty {
                    self.selectedAddressText = "\(city) – \(state)"
                } else if let city, !city.isEmpty {
                    self.selectedAddressText = city
                } else {
                    self.selectedAddressText = "Sua localização"
                }
            }
        }
    }
}

// MARK: - Background (Mapa real)
private struct LiveMapBackground: View {
    @Binding var region: MKCoordinateRegion

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .disabled(true)
            .overlay(
                Rectangle().fill(.white.opacity(0.45)) // mantém a UI legível
            )
            .blur(radius: 1.5)
            .saturation(0.9)
    }
}

// MARK: - Pin animado
private struct AnimatedPinLogo: View {
    let isAnimating: Bool

    var body: some View {
        Image("memoriaVivaLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 190, height: 190) // ⬅️ PIN MAIOR
            .shadow(color: .black.opacity(0.22), radius: 22, x: 0, y: 16)
            .scaleEffect(isAnimating ? 1.0 : 0.94)
            .offset(y: isAnimating ? -14 : 10) // bounce mais evidente
            .animation(
                .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
}


private struct PinRings: View {
    let isAnimating: Bool

    var body: some View {
        ZStack {
            ring(delay: 0.00)
            ring(delay: 0.40)
            ring(delay: 0.80)
        }
        .offset(y: 40)
    }

    private func ring(delay: Double) -> some View {
        Circle()
            .strokeBorder(.green.opacity(0.35), lineWidth: 3)
            .frame(width: 42, height: 42)
            .scaleEffect(isAnimating ? 2.8 : 0.9)
            .opacity(isAnimating ? 0.0 : 0.85)
            .animation(
                .easeOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: isAnimating
            )
    }
}

// MARK: - Loader
private struct LoadingPills: View {
    @State private var activeIndex = 0
    private let count = 3

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index == activeIndex ? 1.0 : 0.35))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
        .padding(.top, 18)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % count
            }
        }
    }
}

