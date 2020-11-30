//
//  User.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/26/20.
//

import Foundation
import RealmSwift

class User: Object {
    @objc dynamic var id: String? = ""
    @objc dynamic var username: String? = ""
    @objc dynamic var password: String? = ""
    
    convenience init(id: String?, username: String?, password: String?) {
        self.init()
        self.id = id
        self.username = username
        self.password = password
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
