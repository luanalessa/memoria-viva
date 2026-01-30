import SwiftUI
import MapKit
import CoreLocation

// ✅ Annotation separada e simples
final class MVAnnotation: NSObject, MKAnnotation {
    let point: MVPoint
    var coordinate: CLLocationCoordinate2D { point.coordinate }
    var title: String? { point.titulo }
    var subtitle: String? { point.categoria }

    init(point: MVPoint) { self.point = point }
}

struct MVMapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var points: [MVPoint]
    var onSelect: (MVPoint) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.setRegion(region, animated: false)
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {

        // ✅ 1) SwiftUI -> MKMapView: sempre aplica quando mudou (sem travar por flag)
        let centerChanged =
            abs(map.region.center.latitude - region.center.latitude) > 0.000001 ||
            abs(map.region.center.longitude - region.center.longitude) > 0.000001

        let spanChanged =
            abs(map.region.span.latitudeDelta - region.span.latitudeDelta) > 0.000001 ||
            abs(map.region.span.longitudeDelta - region.span.longitudeDelta) > 0.000001

        if centerChanged || spanChanged {
            context.coordinator.isSettingRegionProgrammatically = true
            map.setRegion(region, animated: true)

            // ✅ fallback: mesmo se regionDidChange não disparar, destrava
            DispatchQueue.main.async {
                context.coordinator.isSettingRegionProgrammatically = false
            }
        }

        // ✅ 2) Atualiza pins por diff (não remove tudo)
        let existing = map.annotations.compactMap { $0 as? MVAnnotation }
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.point.id, $0) })
        let incomingIds = Set(points.map(\.id))

        // Remove os que não existem mais
        let toRemove = existing.filter { !incomingIds.contains($0.point.id) }
        if !toRemove.isEmpty {
            map.removeAnnotations(toRemove)
        }

        // Adiciona os novos
        let toAdd = points.compactMap { p -> MVAnnotation? in
            if existingById[p.id] != nil { return nil }
            return MVAnnotation(point: p)
        }
        if !toAdd.isEmpty {
            map.addAnnotations(toAdd)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MVMapKitView
        var isSettingRegionProgrammatically = false

        init(_ parent: MVMapKitView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // ✅ Se a mudança veio do SwiftUI, não reflete de volta (evita loop)
            if isSettingRegionProgrammatically { return }

            // ✅ Usuário mexeu no mapa -> atualiza o binding
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let id = "mv-pin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)

            view.annotation = annotation
            view.canShowCallout = false
            view.collisionMode = .none
            view.displayPriority = .required
            view.zPriority = .max

            if let a = annotation as? MVAnnotation {
                switch a.point.categoriaApp.lowercased() {
                case "memoria":
                    view.markerTintColor = UIColor(red: 0.86, green: 0.43, blue: 0.23, alpha: 1.0)
                    view.glyphImage = UIImage(systemName: "book")
                case "evento":
                    view.markerTintColor = UIColor(red: 0.90, green: 0.70, blue: 0.22, alpha: 1.0)
                    view.glyphImage = UIImage(systemName: "calendar")
                case "onde_ir", "onde ir":
                    view.markerTintColor = UIColor(red: 0.30, green: 0.62, blue: 0.39, alpha: 1.0)
                    view.glyphImage = UIImage(systemName: "storefront")
                default:
                    view.markerTintColor = .systemGray
                    view.glyphImage = UIImage(systemName: "mappin")
                }
            }

            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            parent.onSelect(ann.point)
        }
    }
}
