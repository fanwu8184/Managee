//
//  CurrentUser.swift
//  Managee
//
//  Created by Fan Wu on 12/4/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation

var curUser: CurrentUser?

class CurrentUser: User {
    
    var email: String? { return dataService.currentUserEmail }
    var myGroups = [MyGroup]()
    var isEmailVerified: Bool? { return dataService.currentUserIsEmailVerified }
    let reauthenticationErrorMessage = FirebaseService.reauthenticationErrorMessage
    
    //-----------------------------------------GENERAL---------------------------------------------------------
    //sign up with a completion to deal with error
    class func signUp(email: String, password: String, completion: ((String?) -> Void)?) {
        dataService.signUp(userEmail: email, userPassword: password) { (errMsg) in completion?(errMsg) }
    }
    
    //sign in with a completion to deal with error
    class func signIn(email: String, password: String, completion: ((String?) -> Void)?) {
        dataService.signIn(userEmail: email, userPassword: password) { (errMsg) in completion?(errMsg) }
    }
    
    //send a password reset mail to a user with a completion to deal with an error
    class func forgotPassword(email: String, completion: ((String?) -> Void)?) {
        dataService.forgotPassword(userEmail: email) { (errMsg) in completion?(errMsg) }
    }
    
    //logout
    func logout() {
        inactivate()
        dataService.logout()
    }
    
    //send a verification email to current user with a completion to deal with an error
    func sendVerificationEmail(completion: ((String?) -> Void)?) {
        dataService.sendVerificationEmail { (errMsg) in completion?(errMsg) }
    }
    
    //update current user's email with a completion to deal with an error
    func updateEmail(email: String, completion: ((String?) -> Void)?) {
        dataService.updateEmail(newEmail: email) { (errMsg) in
            if errMsg == nil { self.sendVerificationEmail(completion: nil)}
            completion?(errMsg)
        }
    }
    
    //update current user's password with a completion to deal with an error
    func updatePassword(password: String, completion: ((String?) -> Void)?) {
        dataService.updatePassword(newPassword: password) { (errMsg) in completion?(errMsg) }
    }
    
    //delete current user's account with a completion to deal with error
    func deleteAccount(completion: ((String?) -> Void)?) {
        if myGroups.isEmpty {
            inactivate()
            deleteImageAndData { (delErrMsg) in
                if delErrMsg == nil {
                    dataService.deleteAccount { (errMsg) in completion?(errMsg) }
                } else { completion?(delErrMsg) }
            }
        } else { completion?(Constants.removeAllGroupsBeforeDeleteAccount) }
    }
    
    //reauthenticate current user with a completion to deal with an error
    func reauthenticate(password: String, completion: ((String?) -> Void)?) {
        dataService.reauthenticate(inputPassword: password) { (errMsg) in completion?(errMsg) }
    }
    
    //-----------------------------------------SPECIFIC--------------------------------------------------------
    //save current user's image and data with a completion to deal with an error
    func saveImageAndProfileData(imageData: Data?, completion: ((String?) -> Void)?) {
        if let userImageData =  imageData {
            dataService.saveCurrentUserImage(imageData: userImageData) { (errMsg, url) in
                if errMsg == nil {
                    self.imageURL = url
                    self.saveProfileData { (dataErrMsg) in completion?(dataErrMsg) }
                } else { completion?(errMsg) }
            }
        } else { saveProfileData{ (errMsg) in completion?(errMsg) } }
    }
    
    //join a group with a completion to deal with an error
    func join(into group: Group, completion: ((String?) -> Void)?) {
        let myGroup = MyGroup(from: group, gidStatus: false)
        let member = Member(id: uid, of: myGroup, sta: false, isM: false)
        dataService.userJoinGroup(userID: uid, gidValue: myGroup.formatForGid(order: -1), groupID: group.gid, memberValue: member.formatForMemberData()) { (errMsg) in completion?(errMsg) }
    }
    
    //create a new group with a completion to deal with an error
    func createGid(ord: Int, completion: ((String?) -> Void)?) {
        let newGroup = MyGroup(currentUserID: uid)
        dataService.saveUserGidAndGroupData(userID: uid, gidValue: newGroup.formatForGid(order: ord), groupID: newGroup.gid, groupValue: newGroup.formatForNewGroup()) { (errMsg) in completion?(errMsg) }
    }
    
    //remove a gid with a completion to deal with an error
    func removeGid(of myGroup: MyGroup, completion: ((String?) -> Void)?) {
        myGroup.loadCreaterUid {
            if self.uid == myGroup.createrUid {
                myGroup.members.removeAll()
                myGroup.loadMembers {
                    //if there is no one left at all, delete the group and associated activities
                    if myGroup.members.count == 1 {
                        myGroup.loadActivities {
                            //delete associated activities' data
                            for activity in myGroup.activities { activity.deleteImageAndData(completion: nil) }
                            dataService.removeUserGidAndGroupData(userID: self.uid, groupID: myGroup.gid) { (errMsg) in
                                if errMsg == nil { myGroup.deleteImage(completion: nil) }
                                completion?(errMsg)
                            }
                        }
                    } else { completion?(Constants.assignOwner) }
                }
            } else {
                dataService.removeUserGidAndGroupMember(memberID: self.uid, groupID: myGroup.gid) { (errMsg) in completion?(errMsg) }
            }
        }
    }
    
    //reorder myGroups' order with a completion to deal with an error
    func reorderMyGroups(fromIndex oldIndex: Int, toIndex newIndex: Int, completion: ((String?) -> Void)?) {
        let myGroup = myGroups[oldIndex]
        myGroups.remove(at: oldIndex)
        myGroups.insert(myGroup, at: newIndex)
        saveMyGroupsData { (errMsg) in completion?(errMsg) }
    }
    
    //set up gids observer(added, removed, changed)
    func setUpGidsObserver(observerAction: ((observerEvenType, Int) -> Void)?) {
        dataService.setUpGidsObserver(userID: uid) { (evenType, gid, status) in
            guard let sta = status else { return }
            if evenType == .added {
                dataService.fetchGroupCreaterUidData(groupID: gid) { (uid) in
                    guard let cUid = uid else { return }
                    let myGroup = MyGroup(groupID: gid, createrUid: cUid, gidStatus: sta)
                    myGroup.loadProfileData {
                        self.myGroups.append(myGroup)
                        observerAction?(evenType, self.myGroups.count - 1)
                    }
                }
            }
            if evenType == .removed {
                guard let index = (self.myGroups.index { $0.gid == gid }) else { return }
                self.myGroups.remove(at: index)
                self.saveMyGroupsData(completion: nil)
                observerAction?(evenType, index)
            }
            if evenType == .changed {
                for (index, myGroup) in self.myGroups.enumerated() {
                    if myGroup.gid == gid && myGroup.status != sta {
                        myGroup.status = sta
                        observerAction?(evenType, index)
                        break
                    }
                }
            }
        }
    }
    
    func removeGidsObserver() { dataService.removeGidsObserver(userID: uid) }
    
    //current user start to be active
    func activate(observerAction obsAction: (() -> Void)?, completion: ((String?) -> Void)?) {
        dataService.activateCurrentUser(observerAction: { obsAction?() }) { (errMsg) in completion?(errMsg) }
    }
    
    //current user start to be inactive
    func inactivate() { dataService.inactivateCurrentUser() }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    //save profile data with a completion to deal with an error
    private func saveProfileData(completion: ((String?) -> Void)?) {
        dataService.saveUserProfileData(userID: uid, value: formatForProfile()) { (errMsg) in completion?(errMsg) }
    }
    
    private func formatForMyGroups() -> [String: Any] {
        var format = [String: Any]()
        for (index, myGroup) in myGroups.enumerated() { format[myGroup.gid] = [FirebaseService.Constants.status: myGroup.status, FirebaseService.Constants.order: index] }
        return format
    }
    
    //save myGroups data with a completion to deal with an error
    private func saveMyGroupsData(completion: ((String?) -> Void)?) {
        dataService.saveUserGidsData(userID: uid, value: formatForMyGroups()) { (errMsg) in completion?(errMsg) }
    }
    
    //delete current user image and data with a completion to deal with an error
    private func deleteImageAndData(completion: ((String?) -> Void)?) {
        dataService.deleteCurrentUserData { (dataErrMsg) in
            if dataErrMsg == nil { dataService.deleteCurrentUserImage(deleteCompletion: nil) }
            completion?(dataErrMsg)
        }
    }
}
