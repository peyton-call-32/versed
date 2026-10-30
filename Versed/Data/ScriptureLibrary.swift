import Foundation

/// All scripture text bundled with the app, loaded from `Resources/Scriptures`.
///
/// The files are made by `Scripts/build_scriptures.py`.
struct ScriptureLibrary: Sendable {
    /// Volume file names, in the order they appear in the app.
    static let volumeIDs = ["ot", "nt", "bofm", "dc", "pgp"]

    let volumes: [Volume]
    private let booksByID: [String: Book]

    init(volumes: [Volume]) {
        self.volumes = volumes
        self.booksByID = Dictionary(
            uniqueKeysWithValues: volumes.flatMap(\.books).map { ($0.id, $0) }
        )
    }

    /// Reads every volume from the app bundle. Takes a moment, so call it off the main thread.
    static func loadBundled(from bundle: Bundle = .main) throws -> ScriptureLibrary {
        let decoder = JSONDecoder()
        let volumes = try volumeIDs.map { id in
            guard let url = bundle.url(forResource: id, withExtension: "json") else {
                throw LoadError.missingFile(id)
            }
            return try decoder.decode(Volume.self, from: Data(contentsOf: url))
        }
        return ScriptureLibrary(volumes: volumes)
    }

    func book(id: String) -> Book? {
        booksByID[id]
    }

    func verse(_ id: VerseID) -> Verse? {
        book(id: id.bookID)?
            .verses(inChapter: id.chapter)
            .first { $0.id == id }
    }

    var verseCount: Int {
        volumes.flatMap(\.books).flatMap(\.chapters).reduce(0) { $0 + $1.count }
    }

    enum LoadError: Error {
        case missingFile(String)
    }
}
