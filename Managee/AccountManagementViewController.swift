//
//  AccountManagementViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/10/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class AccountManagementViewController: UIViewController {
    
    private struct UIText {
        static let changeEmailLabel = "Please enter your new email below:"
        static let changeEmailPlaceholder = "New Email"
        static let changePasswordLabel = "Please enter your new password below:"
        static let changePasswordPlaceholder = "New Password"
        static let deleteAccountLabel = "Please tap on the 'Done' Button to confirm"
    }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    var segueIdentifier: String!
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        guard let identifier = segueIdentifier else { return }
        switch identifier {
        case MStoryboard.segueChangeEmail: changeEmail()
        case MStoryboard.segueChangePassword: changePassword()
        case MStoryboard.segueDeleteAccount: deleteAccount()
        default: break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func updateUI() {
        guard let identifier = segueIdentifier else { return }
        self.navigationItem.title = identifier
        switch identifier {
        case MStoryboard.segueChangeEmail:
            label.text = UIText.changeEmailLabel
            inputTextField.placeholder = UIText.changeEmailPlaceholder
        case MStoryboard.segueChangePassword:
            label.text = UIText.changePasswordLabel
            inputTextField.placeholder = UIText.changePasswordPlaceholder
            inputTextField.isSecureTextEntry = true
        case MStoryboard.segueDeleteAccount:
            label.text = UIText.deleteAccountLabel
            inputTextField.isHidden = true
        default:
            break
        }
    }
    
    private func changeEmail() {
        guard let newEmail = inputTextField.text else { return }
        ProgressHud.processing(to: self.view, block: true)
        curUser?.updateEmail(email: newEmail) { (errMsg) in
            ProgressHud.hideProcessing(to: self.view)
            if let m = errMsg { self.reauthenticate(errorMessage: m, completion: self.changeEmail) } else {
                curUser?.logout()
                curUser = nil
                ProgressHud.message(to: self.view, msgTitle: Constants.successfullyChangeEmailTitle, msg: Constants.successfullyChangeEmailMessage, block: true)
                //after hud message is done, go to login page to ask users to sign in with new email
                DispatchQueue.main.asyncAfter(deadline: .now() + ProgressHud.duration) {
                    _ = self.navigationController?.popViewController(animated: true)
                    self.goToLoginView()
                }
            }
        }
    }
    
    private func changePassword() {
        guard let newPassword = inputTextField.text else { return }
        ProgressHud.processing(to: self.view, block: true)
        curUser?.updatePassword(password: newPassword) { (errMsg) in
            ProgressHud.hideProcessing(to: self.view)
            if let m = errMsg { self.reauthenticate(errorMessage: m, completion: self.changePassword) } else {
                ProgressHud.message(to: self.view, msgTitle: Constants.successfullyChangePasswordTitle, block: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + ProgressHud.duration) {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func deleteAccount() {
        ProgressHud.processing(to: self.view, block: true)
        curUser?.deleteAccount { (errMsg) in
            ProgressHud.hideProcessing(to: self.view)
            if let m = errMsg { self.reauthenticate(errorMessage: m, completion: self.deleteAccount) } else {
                curUser = nil
                ProgressHud.message(to: self.view, msgTitle: Constants.successfullyDeleteAccountTitle, block: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + ProgressHud.duration) {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func reauthenticate(errorMessage: String, completion: (() -> Void)?) {
        if errorMessage == curUser?.reauthenticationErrorMessage {
            pushAlertForReauthentication { (password) in
                if password == "" { ProgressHud.message(to: self.view, msg: Constants.missingPassword) } else {
                    ProgressHud.processing(to: self.view, block: true)
                    guard let pw = password else { return }
                    curUser?.reauthenticate(password: pw) { (errMsg) in
                        ProgressHud.hideProcessing(to: self.view)
                        if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } else { completion?() }
                    }
                }
            }
        } else { ProgressHud.message(to: self.view, msg: errorMessage) }
    }
}
