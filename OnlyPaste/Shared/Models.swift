import Foundation

struct ClipItem: Codable, Identifiable, Hashable {
    let id: UUID
    var content: String
    var summary: String?
    let createdAt: Date

    init(id: UUID = UUID(), content: String, summary: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.summary = summary
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey { case id, content, summary, createdAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        content = try c.decode(String.self, forKey: .content)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(summary, forKey: .summary)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct ClipFolder: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var items: [ClipItem]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, items: [ClipItem] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
    }
}

struct StockPool: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var items: [ClipItem]
    var separator: String
    let createdAt: Date

    init(id: UUID = UUID(), name: String, items: [ClipItem] = [], separator: String = "\n", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.items = items
        self.separator = separator
        self.createdAt = createdAt
    }

    static func split(_ raw: String, by separator: String) -> [ClipItem] {
        let parts: [String]
        if separator == "\n" {
            parts = raw.components(separatedBy: .newlines)
        } else if separator == "," {
            parts = raw.components(separatedBy: ",")
        } else if separator == "tab" {
            parts = raw.components(separatedBy: "\t")
        } else {
            parts = raw.components(separatedBy: separator)
        }
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { ClipItem(content: $0) }
    }
}

struct HistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    var content: String
    let createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

struct AppData: Codable {
    var folders: [ClipFolder] = []
    var stockPools: [StockPool] = []
    var history: [HistoryItem] = []
    var deletedItems: [ClipItem] = []

    static var `default`: AppData {
        AppData(
            folders: [
                ClipFolder(name: "常用语"),
                ClipFolder(name: "工作"),
                ClipFolder(name: "社群"),
                ClipFolder(name: "营销"),
                ClipFolder(name: "兑换码")
            ]
        )
    }
}
