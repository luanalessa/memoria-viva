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
    let categoriaApp: String      // "memoria" | "evento" | "onde_ir"
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

        return decoded.features.compactMap { f -> MVPoint? in
            guard f.geometry.type.lowercased() == "point", f.geometry.coordinates.count >= 2 else { return nil }

            // GeoJSON = [lon, lat]
            let lon = f.geometry.coordinates[0]
            let lat = f.geometry.coordinates[1]

            // ✅ Normaliza categoria_app para valores canônicos
            let appCat = normalizeCategoriaApp(f.properties.categoria_app)

            // ✅ fallback automático (se não vier no JSON)
            let fallback: String = {
                let t = f.properties.tipo.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if t.contains("mem") { return "memoria" }
                if t.contains("event") { return "evento" } // 🔥 aqui era "eventos" (errado)
                if t.contains("onde") { return "onde_ir" }
                return "memoria"
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

    // MARK: - Helpers

    private static func normalizeCategoriaApp(_ raw: String?) -> String {
        let c = (raw ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if c.isEmpty { return "" }

        // aceita variações comuns e transforma em canônico
        if c == "memoria" || c == "memórias" || c == "memorias" { return "memoria" }
        if c == "evento" || c == "eventos" { return "evento" }
        if c == "onde_ir" || c == "onde ir" || c == "ondeir" { return "onde_ir" }

        // se vier qualquer coisa diferente, devolve vazio pra cair no fallback
        return ""
    }
}
