//
//  NGroup.swift
//  Managee
//
//  Created by Fan Wu on 12/19/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation

class Group {
    
    let gid: String
    var createrUid: String
    var name: String?
    var imageURL: String?
    
    init(currentUserID: String) {
        gid = FirebaseService.autoID
        createrUid = currentUserID
    }
    
    init(key: String, uid: String) {
        gid =  key
        createrUid = uid
    }
    
    //-----------------------------------------GENERAL---------------------------------------------------------
    func formatForProfile() -> [String: Any] {
        return [FirebaseService.Constants.name: name as Any, FirebaseService.Constants.imageURL: imageURL as Any]
    }
    
    func updateProfileData(value: NSDictionary?) {
        if let n = value?[FirebaseService.Constants.name] as? String { name = n }
        if let url = value?[FirebaseService.Constants.imageURL] as? String { imageURL = url }
    }
    
    func loadProfileData(completion: (() -> Void)?) {
        dataService.fetchGroupProfileData(groupID: gid) { (data) in
            self.updateProfileData(value: data)
            completion?()
        }
    }
    
    func loadCreaterUid(completion: (() -> Void)?) {
        dataService.fetchGroupCreaterUidData(groupID: gid) { (uid) in
            guard let cUid = uid else { return }
            self.createrUid = cUid
            completion?()
        }
    }
    
    //check a user whether is a member or not
    func checkMemberStatus(of user: User, completion: @escaping (Bool) -> Void ) {
        dataService.check(memberID: user.uid, ofGroupID: gid) { (isMember) in completion(isMember) }
    }
}

