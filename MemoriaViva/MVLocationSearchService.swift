import Foundation
import MapKit
import CoreLocation

final class MVLocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var results: [MKLocalSearchCompletion] = []
    @Published var shouldShowResults: Bool = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String, near center: CLLocationCoordinate2D) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard q.count >= 2 else {
            clear()
            return
        }

        shouldShowResults = true
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        completer.queryFragment = q
    }

    func clear() {
        results = []
        shouldShowResults = false
        completer.queryFragment = ""
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        clear()
    }

    func resolve(_ completion: MKLocalSearchCompletion,
                 onFound: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            let item = response?.mapItems.first
            let coord = item?.placemark.coordinate
            let title = item?.name ?? completion.title
            onFound(coord, title)
        }
    }
}
