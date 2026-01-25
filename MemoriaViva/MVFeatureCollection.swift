//
//  MVFeatureCollection.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 25/01/26.
//


import Foundation
import CoreLocation

// GeoJSON DTO
struct MVFeatureCollection: Decodable {
    let type: String
    let features: [MVFeature]
}

struct MVFeature: Decodable {
    let type: String
    let id: String?
    let properties: MVProperties
    let geometry: MVGeometry
}

struct MVProperties: Decodable {
    let id: String
    let tipo: String
    let categoria: String
    let titulo: String
    let descricao: String
    let midia: [String]?
    let local_nome: String?
    let fonte: String?
    let status: String?
    let categoria_app: String?
}

struct MVGeometry: Decodable {
    let type: String
    let coordinates: [Double] // [lon, lat]
}

// ✅ O tipo que teu MapView usa

struct MVPoint: Identifiable {
    let id: String
    let tipo: String
    let categoria: String
    let categoriaApp: String
    let titulo: String
    let descricao: String
    let midia: [String]
    let localNome: String
    let fonte: String
    let coordinate: CLLocationCoordinate2D
}

enum MVGeoJSONLoader {
    static func loadPointsFromBundle(filename: String) throws -> [MVPoint] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "geojson") else {
            throw NSError(domain: "MV", code: 1, userInfo: [NSLocalizedDescriptionKey: "GeoJSON não encontrado no bundle"])
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(MVFeatureCollection.self, from: data)

        return decoded.features.compactMap { (f) -> MVPoint? in
            guard f.geometry.type.lowercased() == "point", f.geometry.coordinates.count >= 2 else { return nil }
            let lon = f.geometry.coordinates[0]
            let lat = f.geometry.coordinates[1]

            let appCat = (f.properties.categoria_app ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // fallback automático (se não vier no JSON)
            let fallback: String = {
                let t = f.properties.tipo.lowercased()
                if t.contains("mem") { return "memoria" }
                if t.contains("event") { return "eventos" }
                return "onde_ir"
            }()

            return MVPoint(
                id: f.properties.id,
                tipo: f.properties.tipo,
                categoria: f.properties.categoria,
                categoriaApp: appCat.isEmpty ? fallback : appCat,
                titulo: f.properties.titulo,
                descricao: f.properties.descricao,
                midia: f.properties.midia ?? [],
                localNome: f.properties.local_nome ?? "-",
                fonte: f.properties.fonte ?? "-",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }
    }
}
