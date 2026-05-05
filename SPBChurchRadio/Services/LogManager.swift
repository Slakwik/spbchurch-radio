import Foundation
import Combine
import SwiftUI

/// One log entry — small Codable value so we can persist the buffer to disk.
struct LogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let level: Level
    let source: String?
    let message: String

    enum Level: String, Codable, CaseIterable, Identifiable {
        case info, warning, error

        var id: String { rawValue }

        var label: String {
            switch self {
            case .info:    return "Инфо"
            case .warning: return "Внимание"
            case .error:   return "Ошибка"
            }
        }

        var icon: String {
            switch self {
            case .info:    return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error:   return "xmark.octagon.fill"
            }
        }

        var swiftUIColor: Color {
            switch self {
            case .info:    return .blue
            case .warning: return .orange
            case .error:   return .red
            }
        }
    }
}

/// Application-wide log buffer.
///
/// Thread-safety: this is *not* `@MainActor` — services log from background
/// queues during URLSession callbacks, and forcing them to hop to main first
/// would risk early-launch ordering issues. Internal mutations are serialised
/// on `queue`; @Published updates are dispatched onto the main thread so
/// SwiftUI observers stay safe.
final class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }
    @Published private(set) var entries: [LogEntry] = []

    private let maxEntries = 500
    private static let enabledKey = "log_enabled"
    private let queue = DispatchQueue(label: "com.spbchurch.logmanager", qos: .utility)

    private static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("app_log.json")
    }

    init() {
        // Default ON so users see what's happening on first run; they can
        // disable from Settings.
        self.isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        loadEntries()
    }

    // MARK: - Append

    func log(_ message: String, level: LogEntry.Level = .info, source: String? = nil) {
        // Snapshot the flag — `isEnabled` may be flipped from another thread,
        // but we read it once and treat the read as authoritative for this
        // call. Worst case: one stale message gets through after a toggle.
        guard isEnabled else { return }
        let entry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            source: source,
            message: message
        )

        queue.async { [weak self] in
            guard let self = self else { return }
            var next = self.entries
            next.append(entry)
            if next.count > self.maxEntries {
                next.removeFirst(next.count - self.maxEntries)
            }
            // Push the @Published mutation back onto main so SwiftUI stays happy.
            DispatchQueue.main.async {
                self.entries = next
            }
            self.persist(next)
        }

        #if DEBUG
        let src = source.map { "[\($0)] " } ?? ""
        print("LOG \(level.rawValue.uppercased()) \(src)\(message)")
        #endif
    }

    func info(_ message: String, source: String? = nil)  { log(message, level: .info,    source: source) }
    func warn(_ message: String, source: String? = nil)  { log(message, level: .warning, source: source) }
    func error(_ message: String, source: String? = nil) { log(message, level: .error,   source: source) }

    // MARK: - Mutate

    func clear() {
        DispatchQueue.main.async { self.entries.removeAll() }
        queue.async { [weak self] in self?.persist([]) }
    }

    // MARK: - Export

    /// Serialise the buffer as plain text for ShareLink / save to Files.
    func exportText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let snapshot = entries  // value-type copy
        var lines: [String] = ["SPBChurch Radio · journal export"]
        lines.append("Exported: \(formatter.string(from: Date()))")
        lines.append("Entries:  \(snapshot.count)")
        lines.append(String(repeating: "-", count: 60))
        for e in snapshot {
            let src = e.source.map { " [\($0)]" } ?? ""
            lines.append("\(formatter.string(from: e.timestamp)) \(e.level.rawValue.uppercased())\(src) — \(e.message)")
        }
        return lines.joined(separator: "\n")
    }

    /// Writes export text to a temp file and returns its URL (for ShareLink).
    func exportFileURL() -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("spbchurch-log-\(Int(Date().timeIntervalSince1970)).txt")
        do {
            try exportText().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Persistence

    private func loadEntries() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let saved = try? JSONDecoder().decode([LogEntry].self, from: data) else {
            return
        }
        entries = saved
    }

    private func persist(_ snapshot: [LogEntry]) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
