//
//  MVFeatureCollection.swift
//  MemoriaViva
//
//  Created by Luana Lessa on 25/01/26.
//

import Foundation
import CoreLocation


struct MVHorario: Decodable {
    let status: String?
    let weekday_text: [String]?
}

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

struct MVMidia: Decodable {
    let tipo: [String]?
    let imagens: [MVImagem]?
}

struct MVImagem: Decodable {
    let asset_thumb: String
    let asset_full: String
    let descricao: String?
}

struct MVContato: Decodable {
    let whatsapp: String?
    let instagram: String?
}

struct MVProperties: Decodable {
    let id: String
    let likes_count: Int?
    let tipo: String
    let categoria: String
    let titulo: String
    let descricao: String
    let midia: MVMidia?          // se você já mudou pra objeto
    let local_nome: String?
    let fonte: String?
    let status: String?
    let categoria_app: String?
    let data_exata_inicio: String?
    let data_exata_fim: String?
    let data: String?
    let horario: MVHorario?
    let contato: MVContato?


}

struct MVGeometry: Decodable {
    let type: String
    let coordinates: [Double] // [lon, lat]
}

struct MVPoint: Identifiable {
    let id: String
    let likesCount: Int
    let tipo: String
    let categoria: String
    let categoriaApp: String
    let titulo: String
    let descricao: String
    let localNome: String
    let fonte: String
    let coordinate: CLLocationCoordinate2D
    let imagens: [MVImagem]
    let dataExataInicio: String?
    let dataExataFim: String?
    let dataTexto: String?
    let horario: MVHorario?
    let contato: MVContato?

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
            
            let likes = f.properties.likes_count ?? 0

            return MVPoint(
                id: f.properties.id,
                likesCount: likes,
                tipo: f.properties.tipo,
                categoria: f.properties.categoria,
                categoriaApp: appCat.isEmpty ? fallback : appCat,
                titulo: f.properties.titulo,
                descricao: f.properties.descricao,
                localNome: f.properties.local_nome ?? "-",
                fonte: f.properties.fonte ?? "-",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                imagens: f.properties.midia?.imagens ?? [],
                dataExataInicio: f.properties.data_exata_inicio,
                dataExataFim: f.properties.data_exata_fim,
                dataTexto: f.properties.data,
                horario: f.properties.horario,
                contato: f.properties.contato,
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
