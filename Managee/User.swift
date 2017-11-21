//
//  Nuser.swift
//  Managee
//
//  Created by Fan Wu on 12/3/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation

class User {
    
    var uid: String
    var name: String?
    var imageURL: String?
    
    init(key: String) { uid = key }

    //-----------------------------------------GENERAL---------------------------------------------------------
    func formatForProfile() -> [String: Any] {
        return [FirebaseService.Constants.name: name as Any, FirebaseService.Constants.imageURL: imageURL as Any]
    }
    
    func loadProfileData(completion: (() -> Void)?) {
        dataService.fetchUserProfileData(userID: uid) { (value) in
            self.updateProfile(data: value)
            completion?()
        }
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func updateProfile(data: NSDictionary?) {
        if let n = data?[FirebaseService.Constants.name] as? String { name = n }
        if let url = data?[FirebaseService.Constants.imageURL] as? String { imageURL = url }
    }
}
