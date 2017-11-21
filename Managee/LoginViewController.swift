//
//  NLoginViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/7/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var loginButton: UIButton!
    
    //set the login button's title
    @IBAction func segment(_ sender: UISegmentedControl) {
        let title = sender.titleForSegment(at: sender.selectedSegmentIndex)
        loginButton.setTitle(title, for: .normal)
    }
    
    @IBAction func login(_ sender: UIButton) {
        if emailTextField.text == "" || passwordTextField.text == "" {
            ProgressHud.message(to: self.view, msg: Constants.missingEmailOrPassword)
        } else {
            //logout previous user
            curUser?.logout()
            curUser = nil
            guard let userEmail = emailTextField.text else { return }
            guard let userPassword = passwordTextField.text else { return }
            switch segmentedControl.selectedSegmentIndex {
            case 0: // sign in
                ProgressHud.processing(to: self.view)
                CurrentUser.signIn(email: userEmail, password: userPassword) { (errMsg) in
                    ProgressHud.hideProcessing(to: self.view)
                    if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } else {
                        _ = self.navigationController?.popViewController(animated: true)
                        AppDelegate.activate(extraCompletion: nil)
                    }
                }
            case 1: // sign up
                ProgressHud.processing(to: self.view)
                CurrentUser.signUp(email: userEmail, password: userPassword) { (errMsg) in
                    ProgressHud.hideProcessing(to: self.view)
                    if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } else {
                        AppDelegate.activate { self.sendEmailVerification() }
                    }
                }
            default:
                break
            }
        }
    }
    
    @IBAction func forgotPassword() {
        if emailTextField.text == "" {
            ProgressHud.message(to: self.view, msg: Constants.forgotPasswordErrorMessage)
        } else {
            guard let userEmail = emailTextField.text else { return }
            ProgressHud.processing(to: self.view)
            CurrentUser.forgotPassword(email: userEmail) { (errMsg) in
                ProgressHud.hideProcessing(to: self.view)
                if let m = errMsg { ProgressHud.message(to: self.view, msg: m)} else {
                    let content = Constants.sendPasswordResetEmailMessage + userEmail
                    ProgressHud.message(to: self.view, msgTitle: Constants.sendPasswordResetEmailTitle, msg: content)
                }
            }
        }
    }
}
