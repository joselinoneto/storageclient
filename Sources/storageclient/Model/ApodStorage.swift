//
//  ApodStorage.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import ToolboxStorageClient

public class ApodStorage: LocalItem  {
    public var id: UUID?
    public var date: String?
    public var postedDate: Date?
    public var explanation: String?
    public var mediaType: String?
    public var thumbnailUrl: String?
    public var title: String?
    public var url: String?
    public var hdurl: String?
    public var copyright: String?
    
    public static func createTable() {
        
    }
}
