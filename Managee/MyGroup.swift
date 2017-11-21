//
//  MyGroup.swift
//  Managee
//
//  Created by Fan Wu on 1/16/17.
//  Copyright © 2017 8184. All rights reserved.
//

import Foundation

class MyGroup: Group {
    
    var status: Bool
    var currentUserIsManager: Bool?
    var currentUserStatus: Bool?
    var activities = [Activity]()
    var members = [Member]()
    
    override init(currentUserID uid: String) {
        status = true
        super.init(currentUserID: uid)
        fillMembers(with: uid)
    }
    
    init(groupID: String, createrUid: String, gidStatus: Bool) {
        status = gidStatus
        super.init(key: groupID, uid: createrUid)
    }
    
    init(from group: Group, gidStatus: Bool) {
        status = gidStatus
        super.init(key: group.gid, uid: group.createrUid)
    }
    
    func formatForNewGroup() -> [String: Any] {
        return [FirebaseService.Constants.createrUid: createrUid as Any, FirebaseService.Constants.members: formatForMembers()]
    }
    
    func formatForGid(order: Int) -> [String: Any] {
        return [FirebaseService.Constants.status: status, FirebaseService.Constants.order: order]
    }
    
    func formatForMembers() -> [String: Any] {
        var format = [String: Any]()
        for member in members { format[member.uid] = [FirebaseService.Constants.status: member.status, FirebaseService.Constants.isManager: member.isManager] }
        return format
    }
    
    //save group's image and data with a completion to deal with an error
    func saveImageAndProfileData(imageData: Data?, completion: ((String?) -> Void)?) {
        if currentUserIsManager == true {
            if let groupImageData =  imageData {
                dataService.saveGroupImage(groupID: gid, imageData: groupImageData) { (errMsg, url) in
                    if errMsg == nil {
                        self.imageURL = url
                        self.saveProfileData { (dataErrMsg) in completion?(dataErrMsg) }
                    } else { completion?(errMsg) }
                }
            } else { saveProfileData { (errMsg) in completion?(errMsg) } }
        } else { completion?(Constants.notManager) }
    }
    
    func deleteImage(completion: ((String?) -> Void)?) {
        dataService.deleteGroupImage(groupID: self.gid) { (errMsg) in completion?(errMsg) }
    }
    
    func saveMembersData(completion: ((String?) -> Void)?) {
        if currentUserIsManager == true || createrUid == curUser?.uid {
            dataService.saveGroupMembersData(groupID: gid, save: formatForMembers()) { (errMsg) in completion?(errMsg) }
        } else { completion?(Constants.noPermission) }
    }
    
    func loadMembers(completion: (() -> Void)?) {
        members.removeAll()
        dataService.fetchGroupMembersData(groupID: gid) { (mems) in
            for mem in mems {
                let member = Member(id: mem.0, of: self, sta: mem.1, isM: mem.2)
                self.members.append(member)
            }
            completion?()
        }
    }
    
    func loadActivities(completion: (() -> Void)?) {
        activities.removeAll()
        dataService.fetchGroupAidsData(groupID: gid) { (aids) in
            for aid in aids {
                let activity = Activity(key: aid, of: self)
                self.activities.append(activity)
            }
            completion?()
        }
    }
    
    func assign(nextCreater: Member, completion: ((String?) -> Void)?) {
        if curUser?.uid == createrUid {
            if nextCreater.status == false {
                accept(requestFrom: nextCreater) { (acceptErrMsg) in
                    if acceptErrMsg == nil {
                        self.createrUid = nextCreater.uid
                        dataService.saveGroupCreaterUid(groupID: self.gid, value: self.createrUid) { (errMsg) in completion?(errMsg) }
                    } else { completion?(acceptErrMsg) }
                }
            } else {
                self.createrUid = nextCreater.uid
                dataService.saveGroupCreaterUid(groupID: self.gid, value: self.createrUid) { (errMsg) in completion?(errMsg) }
            }
        } else { completion?(Constants.notOwner) }
    }
    
    func accept(requestFrom member: Member, completion: ((String?) -> Void)?) {
        if currentUserIsManager == true || createrUid == curUser?.uid {
            dataService.saveUserGidStatusAndGroupMemberStatusData(memberID: member.uid, groupID: gid, save: true) { (errMsg) in completion?(errMsg) }
        } else { completion?(Constants.notManager) }
    }
    
    func remove(member: Member, completion: ((String?) -> Void)?) {
        if currentUserIsManager == true || createrUid == curUser?.uid {
            dataService.removeUserGidAndGroupMember(memberID: member.uid, groupID: gid) { (errMsg) in completion?(errMsg) }
        } else { completion?(Constants.notManager) }
    }
    
    func createAid(completion: ((String?) -> Void)?) {
        if currentUserIsManager == true {
            let newActivity = Activity(of: self)
            dataService.saveGroupAid(groupID: gid, activityID: newActivity.aid) { (errMsg) in completion?(errMsg) }
        } else { completion?(Constants.notManager) }
    }
    
    func removeAid(of activity: Activity, completion: ((String?) -> Void)?) {
        if currentUserIsManager == true {
            dataService.removeGroupAidAndActivityData(groupID: gid, activityID: activity.aid) { (errMsg) in
                if errMsg == nil && activity.imageURL != nil { activity.deleteImage(completion: nil) }
                completion?(errMsg)
            }
        } else { completion?(Constants.notManager) }
    }
    
    func setUpCreaterUidObserver(observerAction: ((String?, String?) -> Void)?) {
        dataService.setUpCreaterUidObserver(groupID: gid) { (uid) in
            guard let cUid = uid else { return }
            self.createrUid = cUid
            let creater = User(key: cUid)
            creater.loadProfileData { observerAction?(creater.name, creater.imageURL) }
        }
    }
    
    func removeCreaterUidObserver() { dataService.removeCreaterUidObserver(groupID: gid) }
    
    func setUpMemberOfCurrentUserObserver() {
        guard let mid = curUser?.uid else { return }
        dataService.setUpMemberObserver(groupID: gid, memberID: mid) { (sta, isM) in
            self.currentUserStatus = sta
            self.currentUserIsManager = isM
        }
    }
    
    func removeMemberOfCurrentUserObserver() {
        guard let mid = curUser?.uid else { return }
        dataService.removeMemberObserver(groupID: gid, memberID: mid)
    }
    
    func setUpAidsObserver(observerAction: ((observerEvenType, Int) -> Void)?) {
        dataService.setUpAidsObserver(groupID: gid) { (evenType, aid) in
            if evenType == .added {
                let activity = Activity(key: aid, of: self)
                activity.loadProfileData {
                    self.activities.insert(activity, at: 0)
                    observerAction?(evenType, 0)
                }
            }
            if evenType == .removed {
                guard let index = (self.activities.index { $0.aid == aid }) else { return }
                self.activities.remove(at: index)
                observerAction?(evenType, index)
            }
        }
    }
    
    func removeAidsObserver() { dataService.removeAidsObserver(groupID: gid) }
    
    func setUpMembersObserver(observerAction: ((observerEvenType, Int) -> Void)?) {
        dataService.setUpMembersObserver(groupID: gid) { (evenType, uid, sta, isM) in
            guard let status = sta else { return }
            guard let isManager = isM else { return }
            if evenType == .added {
                let member = Member(id: uid, of: self, sta: status, isM: isManager)
                member.loadProfileData {
                    self.members.append(member)
                    observerAction?(evenType, self.members.count - 1)
                }
            }
            if evenType == .removed {
                guard let index = (self.members.index { $0.uid == uid }) else { return }
                self.members.remove(at: index)
                observerAction?(evenType, index)
            }
            if evenType == .changed {
                for (index, member) in self.members.enumerated() {
                    if member.uid == uid {
                        member.status = status
                        member.isManager = isManager
                        observerAction?(evenType, index)
                        break
                    }
                }
            }
        }
    }
    
    func removeMembersObserver() { dataService.removeMembersObserver(groupID: gid) }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    //only for override init(currentUserID uid: String)
    private func fillMembers(with cUid: String) {
        let member = Member(id: cUid, of: self, sta: true, isM: true)
        members.append(member)
    }
    
    private func saveProfileData(completion: ((String?) -> Void)?) {
        dataService.saveGroupProfile(groupID: gid, save: formatForProfile()) { (errMsg) in completion?(errMsg) }
    }
}
