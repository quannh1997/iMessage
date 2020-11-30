//
//  FirebaseDatabaseManager.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/28/20.
//

import Foundation
import RealmSwift

struct LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    
    func createUser(user: User) {
        do {
            let realm = try Realm()
            try! realm.write {
                realm.add(user)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func getLastUser() -> User? {
        do {
            let realm = try Realm()
            guard let user = realm.objects(User.self).last else { return nil }
            return user
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
    
    func removeAllUsers() {
        do {
            let realm = try Realm()
            let users = realm.objects(User.self)
            try! realm.write {
                realm.delete(users)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
}
