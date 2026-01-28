import SwiftUI
import MapKit
import CoreLocation

// MARK: - Annotation

final class MVAnnotation: NSObject, MKAnnotation {
    let id: String
    let point: MVPoint

    // ✅ armazenado para permitir jitter
    var coordinate: CLLocationCoordinate2D

    var title: String? { point.titulo }
    var subtitle: String? { point.categoria }

    init(point: MVPoint) {
        self.point = point
        self.id = point.id

        // 🔥 JITTER determinístico (separa pins na mesma coordenada)
        let base = point.coordinate
        let seed = abs(point.id.hashValue % 360)
        let angle = Double(seed) * Double.pi / 180.0
        let r = 0.00018 // ~20m (aumente/diminua se quiser)

        self.coordinate = CLLocationCoordinate2D(
            latitude: base.latitude + r * cos(angle),
            longitude: base.longitude + r * sin(angle)
        )

        super.init()
    }
}

// MARK: - MapKit View

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
        // Mantém região sincronizada (sem briga)
        if map.region.center.latitude != region.center.latitude ||
            map.region.center.longitude != region.center.longitude ||
            map.region.span.latitudeDelta != region.span.latitudeDelta ||
            map.region.span.longitudeDelta != region.span.longitudeDelta {
            map.setRegion(region, animated: true)
        }

        // ✅ Atualiza pins por diff (não remove tudo)
        context.coordinator.syncAnnotations(on: map, with: points)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MVMapKitView
        private var annotationsById: [String: MVAnnotation] = [:]

        init(_ parent: MVMapKitView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        // ✅ Diff sync
        func syncAnnotations(on map: MKMapView, with points: [MVPoint]) {
            let incomingIds = Set(points.map { $0.id })

            // remove os que não existem mais
            let toRemoveIds = annotationsById.keys.filter { !incomingIds.contains($0) }
            if !toRemoveIds.isEmpty {
                let anns = toRemoveIds.compactMap { annotationsById[$0] }
                map.removeAnnotations(anns)
                toRemoveIds.forEach { annotationsById.removeValue(forKey: $0) }
            }

            // adiciona os novos
            for p in points {
                if annotationsById[p.id] == nil {
                    let ann = MVAnnotation(point: p)
                    annotationsById[p.id] = ann
                    map.addAnnotation(ann)
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let reuseId = "mv-pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

            view.annotation = annotation
            view.canShowCallout = true

            // 🔥 evita o MapKit “esconder” pins
            view.displayPriority = .required
            view.collisionMode = .circle
            view.clusteringIdentifier = nil

            // ✅ Cor por categoria_app (memoria/evento/onde_ir)
            if let a = annotation as? MVAnnotation {
                let appCat = a.point.categoriaApp.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                switch appCat {
                case "memoria":
                    view.markerTintColor = UIColor(red: 0.86, green: 0.43, blue: 0.23, alpha: 1.0) // vermelho/laranja do chip
                    view.glyphImage = UIImage(systemName: "book")

                case "evento":
                    view.markerTintColor = UIColor(red: 0.90, green: 0.70, blue: 0.22, alpha: 1.0) // mostarda
                    view.glyphImage = UIImage(systemName: "calendar")

                case "onde_ir", "onde ir":
                    view.markerTintColor = UIColor(red: 0.30, green: 0.62, blue: 0.39, alpha: 1.0) // verde
                    view.glyphImage = UIImage(systemName: "mappin.and.ellipse")

                default:
                    view.markerTintColor = UIColor.systemGray
                    view.glyphImage = UIImage(systemName: "mappin")
                }
            }

            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            parent.onSelect(ann.point)
        }

        // ✅ ao selecionar: traz pra frente
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            view.layer.zPosition = 1000
            parent.onSelect(ann.point)
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            view.layer.zPosition = 0
        }
    }
}
