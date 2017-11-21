//
//  DataService.swift
//  Managee
//
//  Created by Fan Wu on 11/22/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation
import Firebase

let dataService = FirebaseService()

enum observerEvenType {
    case added
    case removed
    case changed
}

class FirebaseService {
    
    struct Constants {
        //general
        static let imagePostfix = ".jpg"
        static let status = "status"
        static let order = "order"
        
        //error
        static let undefinedErrorsNode = "undefinedErrors"
        static let time = "Time"
        
        //profile
        static let profile = "profile"
        static let name = "name"
        static let imageURL = "imageURL"
        
        //user
        static let usersNode = "users"
        static let usersImagesFolderName = "usersImages"
        static let gids = "gids"
        static let loginLog = "loginLog"
        static let lastActivated = "lastActivated"
        
        //group
        static let groupsNode = "groups"
        static let groupsImagesFolderName = "groupsImages"
        static let createrUid = "createrUid"
        static let managersUid = "managersUid"
        static let members = "members"
        static let isManager = "isManager"
        static let aids = "aids"
        
        //activity
        static let activitiesNode = "activities"
        static let activitiesImagesFolderName = "activitiesImages"
        static let signUpMemberIDs = "signUpMemberIDs"
    }
    
    //specific for reauthentication error
    static let reauthenticationErrorMessage = "For security reason, please enter your current password."
    
    static var autoID: String { return FIRDatabase.database().reference().childByAutoId().key }
    private var databaseRef: FIRDatabaseReference { return FIRDatabase.database().reference() }
    private var storageRef: FIRStorageReference { return FIRStorage.storage().reference() }
    private let errorMsgDictionary = [
        //sign in error
        17999: "Invalid Email Form.",
        17011: "The Email Account Has Not Sign Up Yet.",
        17009: "Wrong Password.",
        
        //sign up error
        17007: "The Email Account Is Already In Use.",
        17008: "Invalid Email Form.",
        17026: "The Password Should Be At Least 6 Characters",
        
        //reauthentication error
        17014: FirebaseService.reauthenticationErrorMessage,
        
        //storage error
        -13010: "The File Does Not Exist"
    ]
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - USER
    //---------------------------------------------------------------------------------------------------------
    
    private var currentUser: FIRUser? { return FIRAuth.auth()?.currentUser }
    var currentUserID: String? {return currentUser?.uid }
    var currentUserEmail: String? { return currentUser?.email }
    var currentUserIsEmailVerified: Bool? { return currentUser?.isEmailVerified }
    
    //-----------------------------------------GENERAL---------------------------------------------------------
    //sign up with a completion to deal with a sign up error
    func signUp(userEmail: String, userPassword: String, signUpCompletion: ((String?) -> Void)?) {
        FIRAuth.auth()?.createUser(withEmail: userEmail, password: userPassword) { (firUser, err) in
            signUpCompletion?(self.handleError(error: err))
        }
    }
    
    //sign in with a completion to deal with a sign in error
    func signIn(userEmail: String, userPassword: String, signInCompletion: ((String?) -> Void)?) {
        FIRAuth.auth()?.signIn(withEmail: userEmail, password: userPassword) { (firUser, err) in
            signInCompletion?(self.handleError(error: err))
        }
    }

    //logout
    func logout() { try? FIRAuth.auth()?.signOut() }
    
    //send a verification email to current user with a completion to deal with an error
    func sendVerificationEmail(sendCompletion: ((String?) -> Void)?) {
        currentUser?.sendEmailVerification { (err) in sendCompletion?(self.handleError(cause: "sendVerificationEmail", error: err)) }
    }
    
    //send a password reset mail to a user with a completion to deal with an error
    func forgotPassword(userEmail email: String, sendCompletion: ((String?) -> Void)?) {
        FIRAuth.auth()?.sendPasswordReset(withEmail: email) { (err) in sendCompletion?(self.handleError(cause: "forgotPassword", error: err)) }
    }

    //update current user's email with a completion to deal with an error
    func updateEmail(newEmail: String, updateCompletion: ((String?) -> Void)?) {
        currentUser?.updateEmail(newEmail) { err in updateCompletion?(self.handleError(cause: "updateEmail", error: err)) }
    }
    
    //update current user's password with a completion to deal with an error
    func updatePassword(newPassword: String, updateCompletion: ((String?) -> Void)?) {
        currentUser?.updatePassword(newPassword) { (err) in updateCompletion?(self.handleError(cause: "updatePassword", error: err)) }
    }

    //delete current user's account, and remove all the files and data associated with the users
    func deleteAccount(deleteCompletion: ((String?) -> Void)?) {
        currentUser?.delete { (err) in deleteCompletion?(self.handleError(cause: "deleteAccount", error: err)) }
    }
    
    //reauthenticate current user with a completion to deal with an error
    func reauthenticate(inputPassword: String, reauthCompletion: ((String?) -> Void)?) {
        guard let email = currentUserEmail else { return }
        let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: inputPassword)
        currentUser?.reauthenticate(with: credential) { (err) in reauthCompletion?(self.handleError(cause: "reauthenticate", error: err)) }
    }
    
    //-----------------------------------------SPECIFIC---------------------------------------------------------
    //save a user profile data with a completion to deal with a save error
    func saveUserProfileData(userID: String, value: [String: Any], saveCompletion: ((String?) -> Void)?) {
        let p = fetchUserProfilePath(uid: userID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //save current user's image with a completion to deal with a save error and url of image
    func saveCurrentUserImage(imageData: Data, saveCompletion: ((String?, String?) -> Void)?) {
        guard let id = currentUserID else { return }
        let p = fetchUserImagePath(uid: id)
        saveFile(path: p, fileData: imageData) { (errMsg, url) in saveCompletion?(errMsg, url) }
    }
    
    //save user gids data with a completion to deal with a save error
    func saveUserGidsData(userID: String, value: Any, saveCompletion: ((String?) -> Void)?) {
        let p = fetchUserGidsPath(uid: userID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //fetch user profile data. if there is any error, it will be recorded
    func fetchUserProfileData(userID: String, completion: ((NSDictionary?) -> Void)?) {
        let p = fetchUserProfilePath(uid: userID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            completion?(value)
        }) { (err) in _ = self.handleError(cause: "fetchUserProfileData", error: err) }
    }
    
    //delete current user's data a completion to deal with a delete error
    func deleteCurrentUserData(deleteCompletion: ((String?) -> Void)?) {
        guard let id = currentUserID else { return }
        let p = fetchUserDataPath(uid: id)
        deleteData(path: p) { (errMsg) in deleteCompletion?(errMsg) }
    }
    
    //delete current user's image with a completion to deal with a delete error
    func deleteCurrentUserImage(deleteCompletion: ((String?) -> Void)?) {
        guard let id = currentUserID else { return }
        let p = fetchUserImagePath(uid: id)
        deleteFile(path: p) { (errMsg) in deleteCompletion?(errMsg) }
    }
    
    //reload firebase current user, set up the login log observer, and fetch current user data
    func activateCurrentUser(observerAction: (() -> Void)?, activateCompletion: ((String?) -> Void)?) {
        reloadCurrentUser { (errMsg) in
            if errMsg == nil { self.setUpLoginLogObserver { observerAction?() } }
            activateCompletion?(errMsg)
        }
    }
    
    //remove the login log observer for current user
    func inactivateCurrentUser() {
        guard let uid = currentUserID else { return }
        removeLoginLogObserver(userID: uid)
    }
    
    //set up gids observer(childAdded, childRemoved, childChanged). if there is any error, it will be recorded
    func setUpGidsObserver(userID: String, observerAction: ((observerEvenType, String, Bool?) -> Void)?) {
        func processSnapshotData(snap: FIRDataSnapshot, evenType: observerEvenType) {
            let value = snap.value as? NSDictionary
            let status = value?[Constants.status] as? Bool
            observerAction?(evenType, snap.key, status)
        }
        
        let p = fetchUserGidsPath(uid: userID)
        let groupQuery = databaseRef.child(p).queryOrdered(byChild: Constants.order)
        groupQuery.observe(.childAdded, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .added)
        }) { (err) in _ = self.handleError(cause: "setUpGidsObserver", error: err) }
        
        databaseRef.child(p).observe(.childRemoved, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .removed)
        }) { (err) in _ = self.handleError(cause: "setUpGidsObserver", error: err) }
        
        databaseRef.child(p).observe(.childChanged, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .changed)
        }) { (err) in _ = self.handleError(cause: "setUpGidsObserver", error: err) }
    }
    
    func removeGidsObserver(userID: String) {
        let p = fetchUserGidsPath(uid: userID)
        databaseRef.child(p).removeAllObservers()
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    //fetch a user's data path
    private func fetchUserDataPath(uid: String) -> String { return "/\(Constants.usersNode)/\(uid)" }
    
    //fetch a user's profile data path
    private func fetchUserProfilePath(uid id: String) -> String { return "\(fetchUserDataPath(uid: id))/\(Constants.profile)" }
    
    //fetch a user's gids data path
    private func fetchUserGidsPath(uid id: String) -> String { return "\(fetchUserDataPath(uid: id))/\(Constants.gids)" }
    
    //fetch a user's login log data path
    private func fetchUserLoginLogPath(uid id: String) -> String { return "\(fetchUserDataPath(uid: id))/\(Constants.loginLog)" }
    
    //fetch a user's image path
    private func fetchUserImagePath(uid: String) -> String { return "\(Constants.usersImagesFolderName)/\(uid)\(Constants.imagePostfix)" }
    
    //reload Firebase's current user
    private func reloadCurrentUser(completion: ((String?) -> Void)?) {
        currentUser?.reload { (err) in completion?(self.handleError(cause: "reloadCurrentUser", error: err)) }
    }
    
    //set up the login log observer for current user to detect multi-logins simultaneously
    private func setUpLoginLogObserver(action: (() -> Void)?) {
        guard let id = currentUserID else { return }
        let p = fetchUserLoginLogPath(uid: id)
        //update the login date first
        saveData(path: p, save: [Constants.lastActivated: Date().description]) { (errMsg) in
            if errMsg == nil {
                self.databaseRef.child(p).observe(.childChanged, with: { (firSnapshot) in action?() }) { (err) in
                    _ = self.handleError(cause: "setUpLoginLogObserver", error: err)
                }
            }
        }
    }
    
    //remove the login log observer for a user
    private func removeLoginLogObserver(userID: String) {
        let path = fetchUserLoginLogPath(uid: userID)
        databaseRef.child(path).removeAllObservers()
    }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - GROUP
    //---------------------------------------------------------------------------------------------------------
    //save group profile data with a completion deal with error
    func saveGroupProfile(groupID: String, save value: [String: Any], saveCompletion: ((String?) -> Void)?) {
        let p = fetchGroupProfilePath(of: groupID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //save group members data with a completion deal with an error
    func saveGroupMembersData(groupID: String, save value: Any, saveCompletion: ((String?) -> Void)?) {
        let p = fetchGroupMembersPath(of: groupID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //save group aid data with a completion deal with an error
    func saveGroupAid(groupID: String, activityID: String, saveCompletion: ((String?) -> Void)?) {
        let p = "\(fetchGroupAidsPath(of: groupID))/\(activityID)"
        saveData(path: p, save: true) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    func saveGroupCreaterUid(groupID: String, value: Any, saveCompletion: ((String?) -> Void)?) {
        let p = fetchGroupCreaterUidPath(of: groupID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //save a group's image with a completion to deal with a save error and url of image
    func saveGroupImage(groupID: String, imageData: Data, saveCompletion: ((String?, String?) -> Void)?) {
        let p = fetchGroupImagePath(gid: groupID)
        saveFile(path: p, fileData: imageData) { (errMsg, url) in saveCompletion?(errMsg, url) }
    }
    
    //delete a group's image with a completion to deal with a delete error
    func deleteGroupImage(groupID: String, deleteCompletion: ((String?) -> Void)?) {
        let p = fetchGroupImagePath(gid: groupID)
        deleteFile(path: p) { (errMsg) in deleteCompletion?(errMsg) }
    }
    
    //fetch a profile data with a completion. if there is any error, it will be recorded
    func fetchGroupProfileData(groupID: String, completion: ((NSDictionary?) -> Void)?) {
        let p = fetchGroupProfilePath(of: groupID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            completion?(value)
        }) { (err) in _ = self.handleError(cause: "fetchGroupProfileData", error: err) }
    }
    
    //fetch creater uid with a completion. if there is any error, it will be recorded
    func fetchGroupCreaterUidData(groupID: String, completion: ((String?) -> Void)?) {
        let p = fetchGroupCreaterUidPath(of: groupID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? String
            completion?(value)
        }) { (err) in _ = self.handleError(cause: "fetchGroupProfileData", error: err) }
    }
    
    //fetch members data with a completion. if there is any error, it will be recorded
    func fetchGroupMembersData(groupID: String, completion: (([(String, Bool, Bool)]) -> Void)?) {
        let p = fetchGroupMembersPath(of: groupID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            var members = [(String, Bool, Bool)]()
            if let value = snapshot.value as? NSDictionary {
                for (uid, midDic) in value {
                    if let mid = uid as? String,
                        let midValue = midDic as? NSDictionary,
                        let status = midValue[Constants.status] as? Bool,
                        let isManager = midValue[Constants.isManager] as? Bool {
                        members.append((mid, status, isManager))
                    }
                }
            }
            completion?(members)
        }) { (err) in _ = self.handleError(cause: "fetchGroupProfileData", error: err) }
    }
    
    func fetchGroupAidsData(groupID: String, completion: (([String]) -> Void)?) {
        let p = fetchGroupAidsPath(of: groupID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            var aids = [String]()
            if let value = snapshot.value as? NSDictionary {
                for key in value.allKeys { if let aid = key as? String { aids.append(aid) } }
            }
            completion?(aids)
        }) { (err) in _ = self.handleError(cause: "fetchGroupAidsData", error: err) }
    }
    
    //check a member uid if it belongs to a group
    func check(memberID: String, ofGroupID: String, completion: ((Bool) -> Void)?) {
        let p = "\(fetchGroupMembersPath(of: ofGroupID))/\(memberID)"
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value as? NSObject == NSNull() { completion?(false) } else { completion?(true) }
        }) { (err) in _ = self.handleError(cause: "check", error: err) }
    }
    
    //search a group by its name with a completion. if there is any error, it will be recorded
    func searchGroupByName(searchContent: String, completion: ((String, String?, NSDictionary?) -> Void)?) {
        let searchField = "\(Constants.profile)/\(Constants.name)"
        let groupQuery = databaseRef.child(Constants.groupsNode).queryOrdered(byChild: searchField).queryEqual(toValue: searchContent)
        groupQuery.observeSingleEvent(of: .value, with: { (snapshot) in
            for snap in snapshot.children {
                let key = (snap as! FIRDataSnapshot).key
                let value = (snap as! FIRDataSnapshot).value as? NSDictionary
                let createrUid = value?[Constants.createrUid] as? String
                let profile = value?[Constants.profile] as? NSDictionary
                completion?(key, createrUid, profile)
            }
        }) { (err) in _ = self.handleError(cause: "searchGroupByName", error: err) }
    }
    
    //if there is any error, it will be recorded
    func setUpCreaterUidObserver(groupID: String, observerAction: ((String?) -> Void)?) {
        let p = fetchGroupCreaterUidPath(of: groupID)
        databaseRef.child(p).observe(.value, with: { (firSnapshot) in
            let uid = firSnapshot.value as? String
            observerAction?(uid)
        }) { (err) in _ = self.handleError(cause: "setUpCreaterUidObserver", error: err) }
    }
    
    func removeCreaterUidObserver(groupID: String) {
        let p = fetchGroupCreaterUidPath(of: groupID)
        databaseRef.child(p).removeAllObservers()
    }
    
    //if there is any error, it will be recorded
    func setUpMemberObserver(groupID: String, memberID: String, observerAction: ((Bool?, Bool?) -> Void)?) {
        let p = "\(fetchGroupMembersPath(of: groupID))/\(memberID)"
        databaseRef.child(p).observe(.value, with: { (firSnapshot) in
            let value = firSnapshot.value as? NSDictionary
            let status = value?[Constants.status] as? Bool
            let isManager = value?[Constants.isManager] as? Bool
            observerAction?(status, isManager)
        }) { (err) in _ = self.handleError(cause: "setUpMemberObserver", error: err) }
    }
    
    func removeMemberObserver(groupID: String, memberID: String) {
        let p = "\(fetchGroupMembersPath(of: groupID))/\(memberID)"
        databaseRef.child(p).removeAllObservers()
    }
    
    //set up aids observer(childAdded, childRemoved). if there is any error, it will be recorded
    func setUpAidsObserver(groupID: String, observerAction: ((observerEvenType, String) -> Void)?) {
        let p = fetchGroupAidsPath(of: groupID)
        databaseRef.child(p).observe(.childAdded, with: { (firSnapshot) in
            observerAction?(.added, firSnapshot.key)
        }) { (err) in _ = self.handleError(cause: "setUpAidsObserver", error: err) }
        
        databaseRef.child(p).observe(.childRemoved, with: { (firSnapshot) in
            observerAction?(.removed, firSnapshot.key)
        }) { (err) in _ = self.handleError(cause: "setUpAidsObserver", error: err) }
    }
    
    func removeAidsObserver(groupID: String) {
        let p = fetchGroupAidsPath(of: groupID)
        databaseRef.child(p).removeAllObservers()
    }
    
    //set up members observer(childAdded, childRemoved, childChanged). if there is any error, it will be recorded
    func setUpMembersObserver(groupID: String, observerAction: ((observerEvenType, String, Bool?, Bool?) -> Void)?) {
        func processSnapshotData(snap: FIRDataSnapshot, evenType: observerEvenType) {
            let value = snap.value as? NSDictionary
            let status = value?[Constants.status] as? Bool
            let isManager = value?[Constants.isManager] as? Bool
            observerAction?(evenType, snap.key, status, isManager)
        }
        
        let p = fetchGroupMembersPath(of: groupID)
        databaseRef.child(p).observe(.childAdded, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .added)
        }) { (err) in _ = self.handleError(cause: "setUpMembersObserver", error: err) }
        
        databaseRef.child(p).observe(.childRemoved, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .removed)
        }) { (err) in _ = self.handleError(cause: "setUpMembersObserver", error: err) }
        
        databaseRef.child(p).observe(.childChanged, with: { (firSnapshot) in
            processSnapshotData(snap: firSnapshot, evenType: .changed)
        }) { (err) in _ = self.handleError(cause: "setUpMembersObserver", error: err) }
    }
    
    func removeMembersObserver(groupID: String) {
        let p = fetchGroupMembersPath(of: groupID)
        databaseRef.child(p).removeAllObservers()
    }

    //-----------------------------------------PRIVATE---------------------------------------------------------
    //fetch a group's data path base on the groupID
    private func fetchGroupDataPath(of gid: String) -> String { return "/\(Constants.groupsNode)/\(gid)" }
    
    //fetch a group profile data path
    private func fetchGroupProfilePath(of gid: String) -> String { return "/\(fetchGroupDataPath(of: gid))/\(Constants.profile)" }
    
    //fetch a group createrUid data path
    private func fetchGroupCreaterUidPath(of gid: String) -> String { return "/\(fetchGroupDataPath(of: gid))/\(Constants.createrUid)" }
    
    //fetch a group aids data path
    private func fetchGroupAidsPath(of gid: String) -> String { return "/\(fetchGroupDataPath(of: gid))/\(Constants.aids)" }
    
    //fetch a group members data path
    private func fetchGroupMembersPath(of gid: String) -> String { return "/\(fetchGroupDataPath(of: gid))/\(Constants.members)" }
    
    //fetch a group's file path base on the groupID
    private func fetchGroupImagePath(gid: String) -> String { return "\(Constants.groupsImagesFolderName)/\(gid)\(Constants.imagePostfix)" }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - USER & GROUP
    //---------------------------------------------------------------------------------------------------------
    //save a user's data and a group's data synchronously with a completion to deal with a save error
    func saveUserGidAndGroupData(userID: String, gidValue: Any, groupID: String, groupValue: Any, saveCompletion: ((String?) -> Void)?) {
        let userPath = "\(fetchUserGidsPath(uid: userID))/\(groupID)"
        let groupPath = fetchGroupDataPath(of: groupID)
        saveDataSynchronous(pathA: userPath, valueA: gidValue, pathB: groupPath, valueB: groupValue) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    func removeUserGidAndGroupData(userID: String, groupID: String, completion: ((String?) -> Void)?) {
        let userPath = "\(fetchUserGidsPath(uid: userID))/\(groupID)"
        let groupPath = fetchGroupDataPath(of: groupID)
        saveDataSynchronous(pathA: userPath, valueA: NSNull(), pathB: groupPath, valueB: NSNull()) { (errMsg) in completion?(errMsg) }
    }
    
    //save a user gid's status data and a group member's status data synchronously with a completion to deal with a save error
    func saveUserGidStatusAndGroupMemberStatusData(memberID: String, groupID: String, save value: Any, saveCompletion: ((String?) -> Void)?) {
        let userPath = "\(fetchUserGidsPath(uid: memberID))/\(groupID)/\(Constants.status)"
        let groupPath = "\(fetchGroupMembersPath(of: groupID))/\(memberID)/\(Constants.status)"
        saveDataSynchronous(pathA: userPath, valueA: value, pathB: groupPath, valueB: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //remove a user gid and a group member data data synchronously with a completion to deal with an error
    func removeUserGidAndGroupMember(memberID: String, groupID: String, completion: ((String?) -> Void)?) {
        let userPath = "\(fetchUserGidsPath(uid: memberID))/\(groupID)"
        let groupPath = "\(fetchGroupMembersPath(of: groupID))/\(memberID)"
        saveDataSynchronous(pathA: userPath, valueA: NSNull(), pathB: groupPath, valueB: NSNull()) { (errMsg) in completion?(errMsg) }
    }
    
    //save a user gid and a group member data synchronously with a completion to deal with an error
    func userJoinGroup(userID: String, gidValue: Any, groupID: String, memberValue: Any, saveCompletion: ((String?) -> Void)?) {
        let userPath = "\(fetchUserGidsPath(uid: userID))/\(groupID)"
        let groupPath = "\(fetchGroupMembersPath(of: groupID))/\(userID)"
        saveDataSynchronous(pathA: userPath, valueA: gidValue, pathB: groupPath, valueB: memberValue) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - ACTIVITY
    //---------------------------------------------------------------------------------------------------------
    //save a activity profile data with a completion to deal with a save error
    func saveActivityProfileData(activityID: String, save value: [String: Any], saveCompletion: ((String?) -> Void)?) {
        let p = fetchActivityProfilePath(of: activityID)
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
        
    }
    //save sign up member data with a completion to deal with a save error
    func saveActivitySignUpMemberData(activityID: String, memberID: String, save value: Any, saveCompletion: ((String?) -> Void)?) {
        let p = "\(fetchActivitySignUpMemberIDsPath(of: activityID))/\(memberID)"
        saveData(path: p, save: value) { (errMsg) in saveCompletion?(errMsg) }
    }
    
    //save a activity's image with a completion to deal with a save error and url of image
    func saveActivityImage(activityID: String, imageData: Data, saveCompletion: ((String?, String?) -> Void)?) {
        let p = fetchActivityImagePath(aid: activityID)
        saveFile(path: p, fileData: imageData) { (errMsg, url) in saveCompletion?(errMsg, url) }
    }
    
    //delete a activity data with a completion deal with an error
    func deleteActivityData(activityID: String, deleteCompletion: ((String?) -> Void)?) {
        let p = fetchActivityDataPath(of: activityID)
        deleteData(path: p) { (errMsg) in deleteCompletion?(errMsg) }
    }
    
    //delete a activity's image with a completion to deal with a delete error
    func deleteActivityImage(activityID: String, deleteCompletion: ((String?) -> Void)?) {
        let p = fetchActivityImagePath(aid: activityID)
        deleteFile(path: p) { (errMsg) in deleteCompletion?(errMsg) }
    }
    
    //fetch a activity profile data with a completion. if there is any error, it will be recorded
    func fetchActivityProfile(activityID: String, completion: ((NSDictionary?) -> Void)?) {
        let p = fetchActivityProfilePath(of: activityID)
        databaseRef.child(p).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            completion?(value)
        }) { (err) in _ = self.handleError(cause: "fetchActivityProfile", error: err) }
    }
    
    //set up signUpMemberIDs observer(childAdded, childRemoved). if there is any error, it will be recorded
    func setUpSignUpMemberIDsObserver(activityID: String, observerAction: ((observerEvenType, String) -> Void)?) {
        let p = fetchActivitySignUpMemberIDsPath(of: activityID)
        databaseRef.child(p).observe(.childAdded, with: { (firSnapshot) in
            observerAction?(.added, firSnapshot.key)
        }) { (err) in _ = self.handleError(cause: "setUpSignUpMemberIDsObserver", error: err) }
        
        databaseRef.child(p).observe(.childRemoved, with: { (firSnapshot) in
            observerAction?(.removed, firSnapshot.key)
        }) { (err) in _ = self.handleError(cause: "setUpSignUpMemberIDsObserver", error: err) }
    }
    
    func removeSignUpMemberIDsObserver(activityID: String) {
        let p = fetchActivitySignUpMemberIDsPath(of: activityID)
        databaseRef.child(p).removeAllObservers()
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    //fetch a activity's data path base on the groupID
    private func fetchActivityDataPath(of aid: String) -> String { return "/\(Constants.activitiesNode)/\(aid)" }
    
    //fetch a activity profile data path
    private func fetchActivityProfilePath(of aid: String) -> String { return "/\(fetchActivityDataPath(of: aid))/\(Constants.profile)" }
    
    //fetch a activity signUpMemberIDs path
    private func fetchActivitySignUpMemberIDsPath(of aid: String) -> String { return "/\(fetchActivityDataPath(of: aid))/\(Constants.signUpMemberIDs)" }
    
    //fetch a activity's image path base on the groupID
    private func fetchActivityImagePath(aid: String) -> String {
        return "\(Constants.activitiesImagesFolderName)/\(aid)\(Constants.imagePostfix)"
    }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - GROUP & ACTIVITY
    //---------------------------------------------------------------------------------------------------------
    //save a group's data and a activity's data synchronously with a completion to deal with a save error
    func removeGroupAidAndActivityData(groupID: String, activityID: String, saveCompletion: ((String?) -> Void)?) {
        let groupPath = "\(fetchGroupAidsPath(of: groupID))/\(activityID)"
        let activityPath = fetchActivityDataPath(of: activityID)
        saveDataSynchronous(pathA: groupPath, valueA: NSNull(), pathB: activityPath, valueB: NSNull()) {
            (errMsg) in saveCompletion?(errMsg)
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: - GENERAL PRIVATE
    //---------------------------------------------------------------------------------------------------------
    //fetch an error data path
    private func fetchErrorDataPath(eid: String) -> String { return "/\(Constants.undefinedErrorsNode)/\(eid)" }
    
    //return customized error message and save uncustomized error info. on the database
    private func handleError(cause: String = "NONE", error: Error?) -> String? {
        func localizedDescription(errCode: Int) -> String? {
            let errorDescription = "\(errCode): " + error!.localizedDescription
            saveErrorMessage(action: cause, msg: errorDescription)
            return errorDescription
        }
        
        if error == nil { return nil } else {
            if let code = (error as? NSError)?.code {
                if let errMsg = errorMsgDictionary[code] { return errMsg } else { return localizedDescription(errCode: code) }
            } else { return localizedDescription(errCode: 99999) }
        }
    }
    
    //save error data
    private func saveErrorMessage(action: String, msg: String) {
        let errorID = FirebaseService.autoID
        let p = fetchErrorDataPath(eid: errorID)
        let value = [action: msg, Constants.time: Date().description]
        saveData(path: p, save: value, completion: nil)
    }

    //save a value on a path with a completion to deal with a save error
    private func saveData(path: String, save value: Any, completion: ((String?) -> Void)?) {
        databaseRef.updateChildValues([path: value]) { (err, ref) in completion?(self.handleError(cause: "saveData", error: err)) }
    }
    
    //save two values on two paths synchronously with a completion to deal with a save error
    private func saveDataSynchronous(pathA: String, valueA: Any, pathB: String, valueB: Any, completion: ((String?) -> Void)?) {
        databaseRef.updateChildValues([pathA: valueA, pathB: valueB]) { (err, ref) in completion?(self.handleError(cause: "saveDataSynchronous", error: err)) }
    }
    
    //save three values on three paths synchronously with a completion to deal with a save error
    private func saveDataSynchronous(pathA: String, valueA: Any, pathB: String, valueB: Any, pathC: String, valueC: Any, completion: ((String?) -> Void)?) {
        databaseRef.updateChildValues([pathA: valueA, pathB: valueB, pathC: valueC]) { (err, ref) in completion?(self.handleError(cause: "saveDataSynchronous", error: err)) }
    }
    
    //delete a data on a path with a completion to deal with a delete error
    private func deleteData(path: String, completion: ((String?) -> Void)?) {
        databaseRef.updateChildValues([path: NSNull()]) { (err, ref) in completion?(self.handleError(cause: "deleteData", error: err)) }
    }
    
    //save a file on a path with a completion to deal with a save error and an url of file
    private func saveFile(path: String, fileData: Data, completion: ((String?, String?) -> Void)?) {
        storageRef.child(path).put(fileData, metadata: nil) { (metadata, err) in
            completion?(self.handleError(cause: "saveFile", error: err), metadata?.downloadURL()?.absoluteString)
        }
    }
    
    //delete a file on a path with a completion to deal with a delete error
    private func deleteFile(path: String, completion: ((String?) -> Void)?) {
        storageRef.child(path).delete { (err) in completion?(self.handleError(cause: "deleteFile", error: err)) }
    }
}
