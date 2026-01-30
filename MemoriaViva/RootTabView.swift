import SwiftUI
import CoreLocation

struct RootTabView: View {
    let centerTitle: String
    let cityCenter: CLLocationCoordinate2D

    // 🎨 cor laranja da logo
    private let selectedColor = UIColor(
        red: 0.86,
        green: 0.43,
        blue: 0.23,
        alpha: 1.0
    )

    init(centerTitle: String, cityCenter: CLLocationCoordinate2D) {
        self.centerTitle = centerTitle
        self.cityCenter = cityCenter

        // Fundo branco da TabBar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // Ícone/texto selecionado
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]

        // Ícone/texto não selecionado
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView {
            MapView(centerTitle: centerTitle, cityCenter: cityCenter)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }

            AgendaView(events: [])
                .tabItem {
                    Label("Agenda", systemImage: "calendar")
                }

            SavedView()
                .tabItem {
                    Label("Salvos", systemImage: "bookmark")
                }

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person")
                }
        }
    }
}
