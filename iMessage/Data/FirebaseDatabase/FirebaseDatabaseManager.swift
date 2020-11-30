//
//  FirebaseDatabaseManager.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/12/20.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import ObjectMapper

class FirebaseDatabaseManager {
    static let shared = FirebaseDatabaseManager()
    var ref: DatabaseReference!
    
    func createMessage(message: Message, roomID: String, image: UIImage?) {
        ref = Database.database().reference().child("messages").child(roomID)
        var messageDict = [String: Any]()
        messageDict["userID"] = message.userID
        messageDict["content"] = message.content
        messageDict["create_at"] = message.createdTime
        if let image = image, let userID = message.userID {
            storageImage(image: image, userID: userID, completion: { url in
                messageDict["image_url"] = url.absoluteString
                self.ref.childByAutoId().setValue(messageDict)
            })
        } else {
            ref.childByAutoId().setValue(messageDict)
        }
    }
    
    func storageImage(image: UIImage, userID: String, completion: @escaping (URL) -> ()) {
        let randomID = UUID.init().uuidString
        let uploadRef = Storage.storage().reference().child("images").child(randomID)
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        let uploadMetadata = StorageMetadata.init()
        uploadMetadata.contentType = "image/jpeg"
        
        uploadRef.putData(imageData, metadata: uploadMetadata) { (_, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            uploadRef.downloadURL { (url, error) in
                if let error = error {
                    print("error : " + error.localizedDescription)
                    return
                }
                if let url = url {
                    completion(url)
                }
            }
        }
    }
    
    func getNewestMessage(roomID: String) -> Observable<([Message], UInt)> {
        let messageRef = Database.database().reference().child("messages").child(roomID)
//            .queryOrderedByKey()
            .queryLimited(toLast: 10)
        var messages = [Message]()
        return messageRef.rx_observeEvent(event: .value)
            .map { snapshot -> ([Message], UInt) in
                messages = []
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    let message = child.value as? [String: Any]
                    let content = message?["content"] as? String ?? ""
                    let userID = message?["userID"] as? String ?? ""
                    let imageURL = message?["image_url"] as? String ?? ""
                    let id = child.key
                    messages.append(Message(id: id, content: content, userID: userID, imageURL: URL(string: imageURL)))
                }
                return (messages, snapshot.childrenCount)
            }
    }
    
    func loadMoreMessage(roomID: String, fromKey: String) -> Observable<([Message], UInt)> {
        var count: UInt = 0
        Database.database().reference().child("messages").child(roomID).observe(.value) { snapshot in
            count = snapshot.childrenCount
        }
        
        let messageRef = Database.database().reference().child("messages").child(roomID)
            .queryEnding(atValue: nil, childKey: fromKey)
            .queryLimited(toLast: 11)
        var messages = [Message]()
        return messageRef.rx_observeEvent(event: .value)
            .map { snapshot -> ([Message], UInt) in
                messages = []
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    let message = child.value as? [String: Any]
                    let content = message?["content"] as? String ?? ""
                    let userID = message?["userID"] as? String ?? ""
                    let imageURL = message?["image_url"] as? String ?? ""
                    let id = child.key
                    messages.append(Message(id: id, content: content, userID: userID, imageURL: URL(string: imageURL)))
                }
                if messages.count > 0 {
                    messages.removeLast()
                }
                return (messages, count)
            }
    }
    
    func deleteMessage(roomID: String, messageID: String) -> Error? {
        let ref = Database.database().reference().child("messages").child(roomID).child(messageID)
        var result: Error? = nil
        ref.removeValue { (error, _) in
            result = error
        }
        return result
    }
    
    func editMessage(roomID: String, newMessage: Message) -> Error? {
        guard let messageID = newMessage.id else { return nil }
        let ref = Database.database().reference().child("messages").child(roomID).child(messageID)
        var result: Error? = nil
        var newMessageDict: [String: Any] = [:]
        newMessageDict["userID"] = newMessage.userID
        newMessageDict["content"] = newMessage.content
        newMessageDict["create_at"] = newMessage.createdTime
        newMessageDict["update_at"] = newMessage.updatedTime
        ref.setValue(newMessageDict) { (error, _) in
            result = error
        }
        return result
    }
    
    func createUser(user: User) {
        ref = Database.database().reference().child("users")
        var userDict = [String: Any]()
        userDict["username"] = user.username
        userDict["password"] = user.password
        
        ref.childByAutoId().setValue(userDict)
    }
    
    func getAllUser() -> Observable<([User])> {
        let userRef = Database.database().reference().child("users")
        var users = [User]()
        return userRef.rx_observeEvent(event: .value)
            .map { snapshot -> [User] in
                users = []
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    let user = child.value as? [String: Any]
                    let id = child.key as String
                    let username = user?["username"] as? String ?? ""
                    let password = user?["password"] as? String ?? ""
                    users.append(User(id: id, username: username, password: password))
                }
                return users
            }
    }
    
    func createRoom(room: Room) -> String {
        ref = Database.database().reference().child("rooms")
        var roomDict = [String: Any]()
        roomDict["name"] = room.name
        roomDict["users"] = room.users
        roomDict["messages"] = []
        let newRef = ref.childByAutoId()
        newRef.setValue(roomDict)
        return newRef.key ?? ""
    }
    
    func getAllRoom(username: String) -> Observable<([Room])> {
        let roomRef = Database.database().reference().child("rooms")
        var rooms = [Room]()
        return roomRef.rx_observeEvent(event: .value)
            .map { snapshot -> [Room] in
                rooms = []
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    let room = child.value as? [String: Any]
                    let id = child.key as String
                    let name = room?["name"] as? String ?? ""
                    let users = room?["users"] as? [String] ?? []
                    if users.contains(username) {
                        rooms.append(Room(id: id, name: name, users: users, messages: nil))
                    }
                }
                return rooms
            }
    }
    
    func getRoom(currentUser: String, friend: String) -> Observable<Room?> {
        let roomRef = Database.database().reference().child("rooms")
        var result: Room?
        return roomRef.rx_observeEvent(event: .value)
            .map { snapshot -> Room? in
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    let roomDict = child.value as? [String: Any]
                    let id = child.key as String
                    let name = roomDict?["name"] as? String ?? ""
                    let users = roomDict?["users"] as? [String] ?? []
                    if users.contains(currentUser) && users.contains(friend) {
                        result = Room(id: id, name: name, users: users, messages: nil)
                    } else {
                        result = nil
                    }
                }
                return result
            }
    }
}
