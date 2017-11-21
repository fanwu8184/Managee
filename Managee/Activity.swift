//
//  Activity.swift
//  Managee
//
//  Created by Fan Wu on 1/1/17.
//  Copyright © 2017 8184. All rights reserved.
//

import Foundation

class Activity {
    
    unowned let ofGroup: MyGroup
    let aid: String
    var name: String?
    var imageURL: String?
    var signUpMembers = [User]()
    
    init(of group: MyGroup) {
        aid = FirebaseService.autoID
        ofGroup = group
    }
    
    init(key: String, of group: MyGroup) {
        aid = key
        ofGroup = group
    }
    
    //-----------------------------------------GENERAL---------------------------------------------------------
    //save activity's image and data with a completion to deal with an error
    func saveImageAndData(imageData: Data?, completion: ((String?) -> Void)?) {
        if ofGroup.currentUserIsManager == true {
            if let activityImageData =  imageData {
                dataService.saveActivityImage(activityID: aid, imageData: activityImageData) { (errMsg, url) in
                    if errMsg == nil {
                        self.imageURL = url
                        self.saveProfileData { (dataErrMsg) in completion?(dataErrMsg) }
                    } else { completion?(errMsg) }
                }
            } else { saveProfileData{ (errMsg) in completion?(errMsg) } }
        } else { completion?(Constants.notManager) }
    }
    
    func deleteImageAndData(completion: ((String?) -> Void)?) {
        dataService.deleteActivityData(activityID: aid) { (dataErrMsg) in
            if dataErrMsg == nil {
                dataService.deleteActivityImage(activityID: self.aid) { (imageErrMsg) in completion?(imageErrMsg) }
            } else { completion?(dataErrMsg) }
        }
    }
    
    func deleteImage(completion: ((String?) -> Void)?) {
        dataService.deleteActivityImage(activityID: aid) { (errMsg) in completion?(errMsg) }
    }
    
    func loadProfileData(completion: (() -> Void)?) {
        dataService.fetchActivityProfile(activityID: aid) { (data) in
            if let n = data?[FirebaseService.Constants.name] as? String { self.name = n }
            if let url = data?[FirebaseService.Constants.imageURL] as? String { self.imageURL = url }
            completion?()
        }
    }
    
    func signUp(by member: User, completion: ((String?) -> Void)?) {
        dataService.saveActivitySignUpMemberData(activityID: aid, memberID: member.uid, save: true) { (errMsg) in completion?(errMsg) }
    }
    
    func signOff(by member: User, completion: ((String?) -> Void)?) {
        dataService.saveActivitySignUpMemberData(activityID: aid, memberID: member.uid, save: NSNull()) { (errMsg) in completion?(errMsg) }
    }
    
    func setUpSignUpMemberIDsObserver(observerAction: ((observerEvenType, Int) -> Void)?) {
        dataService.setUpSignUpMemberIDsObserver(activityID: aid) { (evenType, mid) in
            if evenType == .added {
                let user = User(key: mid)
                user.loadProfileData {
                    self.signUpMembers.append(user)
                    observerAction?(evenType, self.signUpMembers.count - 1)
                }
            }
            if evenType == .removed {
                guard let index = (self.signUpMembers.index { $0.uid == mid }) else { return }
                self.signUpMembers.remove(at: index)
                observerAction?(evenType, index)
            }
        }
    }
    
    func removeSignUpMemberIDsObserver() { dataService.removeSignUpMemberIDsObserver(activityID: aid) }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    //data format for saving
    private func formatForProfile() -> [String: Any] {
        return [FirebaseService.Constants.name: name as Any, FirebaseService.Constants.imageURL: imageURL as Any]
    }
    
    //save a activity's data with a completion to deal with an error
    private func saveProfileData(completion: ((String?) -> Void)?) {
        dataService.saveActivityProfileData(activityID: aid, save: formatForProfile()) { (errMsg) in completion?(errMsg) }
    }
}
