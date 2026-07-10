//  PaperService.swift
//  Fetches the daily feed (daily.json) published by the Mac Mini pipeline, maps it to
//  the domain `Paper` model, caches the last good response for offline, and falls back
//  to bundled sample data. The wire format is decoupled from the domain via DTOs.

import Foundation

// MARK: - Domain

struct FeedHeader: Equatable {
    let date: String
    let title: String
    let subtitle: String
}

struct DailyFeed {
    let papers: [Paper]
    let header: FeedHeader?   // optional override of the frequency-derived header
}

/// Where the currently-shown feed came from (drives the offline banner).
enum FeedSource: Equatable {
    case sample            // no URL configured → bundled sample
    case network           // fresh from the Mac Mini feed
    case cache             // last good response, shown offline
    case failed(String)    // load failed and no cache → sample shown
}

// MARK: - Decode entry point (also used by the standalone schema test)

enum PaperFeed {
    static func decode(_ data: Data) throws -> DailyFeed {
        try JSONDecoder().decode(DailyFeedDTO.self, from: data).toDomain()
    }
}

// MARK: - Service

protocol PaperService {
    func loadDailyFeed() async throws -> DailyFeed
}

struct RemotePaperService: PaperService {
    let url: URL
    var session: URLSession = .shared

    func loadDailyFeed() async throws -> DailyFeed {
        let data: Data
        if url.isFileURL {
            data = try Data(contentsOf: url)          // local file feed (testing / same-host)
        } else {
            var req = URLRequest(url: url)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.timeoutInterval = 15
            let (body, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            data = body
        }
        let feed = try PaperFeed.decode(data)
        FeedCache.shared.save(data)                    // cache raw bytes on success
        return feed
    }
}

// MARK: - Disk cache (last good feed → offline)

struct FeedCache {
    static let shared = FeedCache()

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("daily-feed.json")
    }

    func save(_ data: Data) { try? data.write(to: fileURL, options: .atomic) }

    func load() -> DailyFeed? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? PaperFeed.decode(data)
    }
}

// MARK: - Wire format (daily.json) — see Backend/daily.schema.md

private struct DailyFeedDTO: Decodable {
    let version: Int?
    let generatedAt: String?
    let frequency: String?
    let header: HeaderDTO?
    let papers: [PaperDTO]

    struct HeaderDTO: Decodable {
        let date: String?
        let title: String?
        let subtitle: String?
    }

    struct PaperDTO: Decodable {
        let id: String
        let venue: String
        let venueDetail: String?
        let matchScore: Int
        let category: String
        let feedTitle: String
        let authorsShort: String
        let feedAbstract: String
        let tags: [String]
        let titleEN: String
        let titleKO: String
        let authorsEN: String
        let authorsKO: String
        let abstractEN: String
        let abstractKO: String
        let detailTags: [String]?
        let year: String
        let citations: Int
        let readMinutes: Int
        let reason: String
        let reasonEn: String?

        func toPaper() -> Paper {
            Paper(
                id: id,
                venue: venue,
                venueDetail: venueDetail ?? venue,
                matchScore: matchScore,
                filterCategory: category,
                feedTitle: feedTitle,
                authorsShort: authorsShort,
                feedAbstract: feedAbstract,
                tags: tags,
                detailTitleEN: titleEN,
                detailTitleKO: titleKO,
                authorsEN: authorsEN,
                authorsKO: authorsKO,
                abstractEN: abstractEN,
                abstractKO: abstractKO,
                detailTags: detailTags ?? tags,
                year: year,
                citations: citations,
                readMinutes: readMinutes,
                reason: LocalizedString(reason, reasonEn ?? reason)
            )
        }
    }

    func toDomain() -> DailyFeed {
        let mappedHeader: FeedHeader? = {
            guard let h = header, let d = h.date, let t = h.title, let s = h.subtitle else { return nil }
            return FeedHeader(date: d, title: t, subtitle: s)
        }()
        return DailyFeed(papers: papers.map { $0.toPaper() }, header: mappedHeader)
    }
}
