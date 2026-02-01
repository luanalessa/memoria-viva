import Foundation

final class UsersRepository {
    static let shared = UsersRepository()
    private init() {}

    private let fileName = "users.json"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func load() throws -> UsersFile {
        let url = documentsURL

        if !FileManager.default.fileExists(atPath: url.path) {
            // copia do Bundle -> Documents
            guard let bundled = Bundle.main.url(forResource: "users", withExtension: "json") else {
                throw NSError(domain: "UsersRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "users.json não encontrado no Bundle"])
            }
            try FileManager.default.copyItem(at: bundled, to: url)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UsersFile.self, from: data)
    }

    func save(_ file: UsersFile) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(file)
        try data.write(to: documentsURL, options: [.atomic])
    }
}
