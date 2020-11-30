//
//  Message.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/12/20.
//

import Foundation

struct Message {
    var id: String?
    var userID: String?
    var content: String?
    var imageURL: URL?
    var createdTime: Double?
    var updatedTime: Double?
    
    init(id: String? = nil, content: String?, userID: String, imageURL: URL? = nil) {
        self.id = id
        self.userID = userID
        self.content = content
        self.imageURL = imageURL
        self.createdTime = Date().timeIntervalSince1970
    }
}
