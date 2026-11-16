#if os(iOS)
import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers
import StrandDesign

/// A separate, versioned personal journal. Strap tables and shared backups are never rewritten.
@MainActor
final class PersonalAthleteStore: ObservableObject {
    static let shared = PersonalAthleteStore()
    @Published private(set) var archive = PersonalAthleteArchive()
    @Published private(set) var error: String?
    @Published private(set) var loaded = false
    private let url: URL

    private init() {
        url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PersonalAthlete", isDirectory: true)
            .appendingPathComponent("journal-v1.json")
        reload()
    }

    func reload() {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                archive = try Self.decode(Data(contentsOf: url))
            }
            loaded = true
            error = nil
        } catch {
            loaded = false
            self.error = "Não foi possível ler o diário. Os dados existentes foram preservados. Tenta novamente ou restaura uma cópia válida."
        }
    }

    static func decode(_ data: Data) throws -> PersonalAthleteArchive {
        guard data.count <= 20_000_000 else { throw PersonalAthleteArchive.ValidationError.invalid }
        let candidate = try JSONDecoder().decode(PersonalAthleteArchive.self, from: data)
        try candidate.validate()
        return candidate
    }

    @discardableResult
    private func persist(_ candidate: PersonalAthleteArchive, restoring: Bool = false) -> Bool {
        guard loaded || restoring else { return false }
        do {
            try candidate.validate()
            let data = try JSONEncoder().encode(candidate)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            archive = candidate
            loaded = true
            error = nil
            return true
        } catch {
            self.error = "Não foi possível guardar. As alterações não foram aplicadas; verifica os dados e o espaço disponível."
            return false
        }
    }

    func save(_ checkIn: PersonalAthleteCheckIn) -> Bool {
        var candidate = archive
        candidate.checkIns.removeAll { $0.id == checkIn.id }
        candidate.checkIns.append(checkIn)
        return persist(candidate)
    }

    func save(_ session: PersonalAthleteSession) -> Bool {
        var candidate = archive
        candidate.sessions.removeAll { $0.id == session.id }
        candidate.sessions.append(session)
        return persist(candidate)
    }

    func remove(sessionID: UUID) {
        var candidate = archive
        candidate.sessions.removeAll { $0.id == sessionID }
        persist(candidate)
    }

    func restore(_ candidate: PersonalAthleteArchive) -> Bool { persist(candidate, restoring: true) }
}

struct PersonalAthleteDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(archive: PersonalAthleteArchive) throws { data = try JSONEncoder().encode(archive) }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
#endif
