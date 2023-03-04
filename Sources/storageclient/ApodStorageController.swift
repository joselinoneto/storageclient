//
//  File.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import Combine
import ToolboxStorageClient
import GRDB
import tools

public class ApodStorageController {
    // MARK: - Private
    private var cancellables: Set<AnyCancellable> = []
    private let worker: LocalStorageClient<ApodStorage>

    // MARK: - Public
    @Published public var items: [ApodStorage]?
    
    // MARK: - Init
    public init(inMemory: Bool = false) {
        let dbFile: String? = inMemory ? nil : "\(FileStorage.shared.folderUrl?.absoluteString ?? "")/apod.sqlite"
        worker = LocalStorageClient<ApodStorage>(pathToSqlite: dbFile)
        createTable()
        worker.valueObservation()

        worker
            .$items
            .assign(to: \.items, on: self)
            .store(in: &cancellables)
    }

    deinit {
        worker.cancelObservation()
    }
    
    //MARK: - Methods - Public
    public func saveItemsSql(_ items: [ApodStorage]) throws {
        try worker.dbQueue?.write({ db in
            for item in items {
                try db.execute(sql: "INSERT INTO APODSTORAGE (id, date, postedDate, explanation, mediaType, thumbnailUrl, title, url, hdurl, copyright) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                               arguments: [item.id?.uuidString,
                                           item.date,
                                           item.postedDate?.databaseValue,
                                           item.explanation?.noQuote,
                                           item.mediaType,
                                           item.thumbnailUrl,
                                           item.title?.noQuote,
                                           item.url,
                                           item.hdurl,
                                           item.copyright?.noQuote])
            }
        })
    }

    public func saveItems(_ items: [ApodStorage]) throws {
        items.forEach { [weak self] (item: ApodStorage) in
            try? self?.worker.save(item: item)
        }
    }

    public func asyncSaveItem(_ item: ApodStorage) async throws {
        try? await worker.asyncSave(item: item)
    }

    public func searchApods(startMonth: String?, endMonth: String?) throws -> [ApodStorage]? {
        try worker.dbQueue?.read({ db in
            try ApodStorage
                .filter(Column("date") >= startMonth && Column("date") <= endMonth)
                .fetchAll(db)
        })
    }
    
    public func getApod(id: UUID) throws -> ApodStorage? {
        try? worker.get(key: id)
    }

    public func getAllItems() throws -> [ApodStorage]? {
        try worker.getAll()
    }
    
    // MARK: - Methods - Private
    private func createTable() {
        guard let dbQueue: DatabaseQueue = worker.dbQueue else { return }
        try? dbQueue.write { db in
            try db.create(table: "ApodStorage", options: .ifNotExists) { t in
                t.column("id", .text).primaryKey()
                t.column("date", .text)
                t.column("postedDate", .date)
                t.column("explanation", .text)
                t.column("mediaType", .text)
                t.column("thumbnailUrl", .text)
                t.column("title", .text)
                t.column("url", .text)
                t.column("hdurl", .text)
                t.column("copyright", .text)
            }
        }
    }
}
