////
////  BaseMappable+Extension.swift
////  iMessage
////
////  Created by Quan Nguyen on 10/12/20.
////
//
//import Foundation
//import Firebase
//import ObjectMapper
//
//extension BaseMappable {
//    static var firebaseIdKey : String {
//        get {
//            return "FirebaseIdKey"
//        }
//    }
//    init?(snapshot: DataSnapshot) {
//        guard var json = snapshot.value as? [String: Any] else {
//            return nil
//        }
//        json[Self.firebaseIdKey] = snapshot.key as Any
//
//        self.init(snapshot: )
//    }
//}
//
//extension Mapper {
//    func mapArray(snapshot: DataSnapshot) -> [N] {
//        return snapshot.children.map { (child) -> N? in
//            if let childSnap = child as? DataSnapshot {
//                return N(snapshot: childSnap)
//            }
//            return nil
//        }.compactMap { $0 }
//    }
//}
