import SwiftUI
import MapKit
import CoreLocation

final class MVAnnotation: NSObject, MKAnnotation {
    let point: MVPoint
    var coordinate: CLLocationCoordinate2D { point.coordinate }
    var title: String? { point.titulo }
    var subtitle: String? { point.categoria }

    init(point: MVPoint) {
        self.point = point
    }
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
        map.pointOfInterestFilter = .excludingAll // limpa “POIs” padrão (opcional)
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

        // Atualiza pins (simples e estável p/ MVP)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        let annotations = points.map { MVAnnotation(point: $0) }
        map.addAnnotations(annotations)
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
            view.canShowCallout = true

            // Cor por categoria (ajuste se quiser)
            if let a = annotation as? MVAnnotation {
                let cat = a.point.categoria.lowercased()
                if cat.contains("lenda") {
                    view.markerTintColor = UIColor.systemPurple
                    view.glyphImage = UIImage(systemName: "moon.stars")
                } else if cat.contains("tradi") || cat.contains("modo de fazer") {
                    view.markerTintColor = UIColor.systemOrange
                    view.glyphImage = UIImage(systemName: "flame")
                } else {
                    view.markerTintColor = UIColor.systemGreen
                    view.glyphImage = UIImage(systemName: "book")
                }
            }

            // Botão detalhe no callout
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            parent.onSelect(ann.point)
        }

        // Tap direto no pin (sem precisar apertar o i)
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? MVAnnotation else { return }
            parent.onSelect(ann.point)
        }
    }
}
