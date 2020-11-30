//
//  Room.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/29/20.
//

import Foundation

struct Room {
    var id: String?
    var name: String?
    var users: [String]?
    var messages: [Message]?
    
    
    init(id: String?, name: String?, users: [String]?, messages: [Message]?) {
        self.id = id
        self.name = name
        self.users = users
        self.messages = messages
    }
}
