//
//  ConstantsOfStoryboard.swift
//  Managee
//
//  Created by Fan Wu on 12/13/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation

struct MStoryboard {
    static let main = "Main"
    static let loginVC = "loginVC"
    static let myGroupCellIdentifier = "MyGroupCell"
    static let myRequestCellIdentifier = "MyRequestCell"
    static let searchCellIdentifier = "SearchCell"
    static let activityCellIdentifier = "ActivityCell"
    static let memberCellIdentifier = "MemberCell"
    static let requestUserCell = "RequestUserCell"
    static let segueChangeEmail = "Change Email"
    static let segueChangePassword = "Change Password"
    static let segueDeleteAccount = "Delete Accoount"
    static let segueMember = "Member"
    static let segueActivity = "Activity"
}

struct Constants {
    //-----------------------------------------GENERAL---------------------------------------------------------
    static let oops = "Oops!"
    static let great = "Great!"
    static let ok = "OK"
    
    //-----------------------------------------ALERT & HUD---------------------------------------------------------
    static let assignOwner = "Please assign another member as the owner of this group before you quit."
    static let emailVerificationMessage = "If you already verified it, please sign in again"
    static let emailVerificationTitle = "Please Verify Your Email"
    static let forgotPasswordErrorMessage = "Please enter your email."
    static let joinGroup = "You have send the request to the group."
    static let missingEmailOrPassword = "Please enter email and password."
    static let missingPassword = "Please enter password."
    static let needApproval = "Sorry, You need to get approval first."
    static let noOtherMembers = "No other member to assign."
    static let noPermission = "Sorry, You Are Not The Owner or Manager."
    static let notManager = "Sorry, You Are Not Manager."
    static let notOwner = "Sorry, You Are Not The Owner."
    static let passwordTextFieldPlaceholder = "Password"
    static let reauthenticationMessage = "For security reason, please enter your current password."
    static let reauthenticationTitle = "Re-authenticating"
    static let removeAllGroupsBeforeDeleteAccount = "Please remove all your groups before you delete your account."
    static let sendEmailVerification = "Sending A Verification Email To: "
    static let sendEmailVerificationActionTitle = "Send me another verification email"
    static let sendPasswordResetEmailMessage = "An Password Reset Email To "
    static let sendPasswordResetEmailTitle = "Sending..."
    static let simultaneouslyLoginActionTitle = "Reload"
    static let simultaneouslyLoginMessage = "Another device is connecting to this account"
    static let submit = "Submit"
    static let successfullyChangeEmailMessage = "Please verify your new email and sign in with it."
    static let successfullyChangeEmailTitle = "Your New Email Is Set"
    static let successfullyChangePasswordTitle = "Your New Password Is Set"
    static let successfullyDeleteAccountTitle = "Your Account Is Deleted"
    static let successfullySendEmailVerificationMessage = "The verifiation email might take a few seconds to arrive."
    static let successfullySendEmailVerificationTitle = "Please Check Your Email And Verify"
    static let unnamed = "Unnamed"
    
    //-----------------------------------------WIGGLE SETTING---------------------------------------------------------
    static let wiggleBounceY = 4.0
    static let wiggleBounceDuration = 0.12
    static let wiggleBounceDurationVariance = 0.025
    static let wiggleRotateAngle = 0.06
    static let wiggleRotateDuration = 0.10
    static let wiggleRotateDurationVariance = 0.025
}
