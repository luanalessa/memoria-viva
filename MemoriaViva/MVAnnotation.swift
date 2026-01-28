import SwiftUI
import MapKit
import CoreLocation

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
        // Mantém região sincronizada (sem briga)
        if map.region.center.latitude != region.center.latitude ||
            map.region.center.longitude != region.center.longitude ||
            map.region.span.latitudeDelta != region.span.latitudeDelta ||
            map.region.span.longitudeDelta != region.span.longitudeDelta {
            map.setRegion(region, animated: true)
        }

        // Atualiza pins
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        map.addAnnotations(points.map { MVAnnotation(point: $0) })
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MVMapKitView
        init(_ parent: MVMapKitView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let id = "mv-pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)

            view.annotation = annotation

            // ✅ remove o “letreiro”
            view.canShowCallout = false
            view.rightCalloutAccessoryView = nil

            // Cor por categoria_app (ex: memoria/evento/onde_ir)
            if let a = annotation as? MVAnnotation {
                switch a.point.categoriaApp.lowercased() {
                case "memoria":
                    view.markerTintColor = UIColor(red: 0.86, green: 0.43, blue: 0.23, alpha: 1.0) // laranja
                    view.glyphImage = UIImage(systemName: "book")
                case "evento":
                    view.markerTintColor = UIColor(red: 0.90, green: 0.70, blue: 0.22, alpha: 1.0) // mostarda
                    view.glyphImage = UIImage(systemName: "calendar")
                case "onde_ir", "onde ir":
                    view.markerTintColor = UIColor(red: 0.30, green: 0.62, blue: 0.39, alpha: 1.0) // verde
                    view.glyphImage = UIImage(systemName: "storefront")
                default:
                    view.markerTintColor = .systemGray
                    view.glyphImage = UIImage(systemName: "mappin")
                }
            }

            return view
        }

        // ✅ tocar no pin chama seu card pequeno (sem callout)
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            parent.onSelect(ann.point)
        }
    }
}
