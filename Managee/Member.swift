//
//  Member.swift
//  Managee
//
//  Created by Fan Wu on 1/21/17.
//  Copyright © 2017 8184. All rights reserved.
//

import Foundation

class Member: User {
    
    unowned let ofGroup: MyGroup
    var isManager: Bool
    var status: Bool
    
    init(id: String, of group: MyGroup, sta: Bool, isM: Bool) {
        status = sta
        ofGroup = group
        isManager = isM
        super.init(key: id)
    }
    
    func formatForMemberData() -> [String: Any] {
        return [FirebaseService.Constants.isManager: isManager, FirebaseService.Constants.status: status]
    }
}
