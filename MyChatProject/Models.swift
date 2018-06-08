//
//  Models.swift
//  MyChatProject
//
//  Created by Аскар on 22.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Firebase

class MyUser: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
}

class Message: NSObject{
    var fromId: String?
    var toId: String?
    var timestamp: Int?
    var text: String?
    
    var imageUrl: String?
    var imageWidth: Int?
    var imageHeight: Int?
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    var counterOfNotWrittenMessages: Int?
    
}

