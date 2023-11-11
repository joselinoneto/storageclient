//
//  ApodStorage.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import ToolboxStorageClient
import GRDB

public class ApodStorage: LocalItem  {
    public static func == (lhs: ApodStorage, rhs: ApodStorage) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // public static let databaseDateDecodingStrategy: DatabaseDateDecodingStrategy = .timeIntervalSince1970

    public var id: Int?
    public var date: String?
    public var postedDate: Date?
    public var explanation: String?
    public var mediaType: String?
    public var thumbnailUrl: String?
    public var title: String?
    public var url: String?
    public var hdurl: String?
    public var copyright: String?
    public var isFavorite: Bool = false
    
    public init() {
        // self.id = UUID()
    }
}
