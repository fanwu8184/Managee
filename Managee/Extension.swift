//
//  Alert.swift
//  Managee
//
//  Created by Fan Wu on 12/9/16.
//  Copyright © 2016 8184. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func loadData() {}
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //go to login view if users haven't logined
    func goToLoginView() {
        if curUser == nil && !(self is LoginViewController) {
            let storyboard = UIStoryboard(name: MStoryboard.main, bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: MStoryboard.loginVC) as? LoginViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    //send a email verification to current user
    func sendEmailVerification() {
        let window = UIApplication.shared.windows.last!
        guard let email = curUser?.email else { return }
        let message = Constants.sendEmailVerification + email
        ProgressHud.processing(to: window, msg: message)
        curUser?.sendVerificationEmail { (errMsg) in
            ProgressHud.hideProcessing(to: window)
            if let m = errMsg { ProgressHud.message(to: window, msg: m)} else {
                ProgressHud.message(to: window, msgTitle: Constants.successfullySendEmailVerificationTitle, msg: Constants.successfullySendEmailVerificationMessage)
            }
        }
    }
    
    //push a alert if users haven't verify their email
    func requestEmailVerification() { if curUser?.isEmailVerified == false { pushAlertForEmailVerificationReminder() } }
    
    func insertItemForCollectionView(collectionView: UICollectionView, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        collectionView.performBatchUpdates({ collectionView.insertItems(at: [indexPath]) }, completion: nil)
    }
    
    func deleteItemForCollectionView(collectionView: UICollectionView, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        collectionView.performBatchUpdates({ collectionView.deleteItems(at: [indexPath]) }, completion: nil)
    }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: -  VIEW WIGGLING
    //---------------------------------------------------------------------------------------------------------
    //codes below are for the shaking cell animation
    func startWiggle(for view: UIView) {
        func randomize(interval: TimeInterval, withVariance variance: Double) -> Double {
            let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
            return interval + variance * random
        }
        
        //Create rotation animation
        let rotationAnim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnim.values = [-Constants.wiggleRotateAngle, Constants.wiggleRotateAngle]
        rotationAnim.autoreverses = true
        rotationAnim.duration = randomize(interval: Constants.wiggleRotateDuration, withVariance: Constants.wiggleRotateDurationVariance)
        rotationAnim.repeatCount = HUGE
        
        //Create bounce animation
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounceAnimation.values = [Constants.wiggleBounceY, 0]
        bounceAnimation.autoreverses = true
        bounceAnimation.duration = randomize(interval: Constants.wiggleBounceDuration, withVariance: Constants.wiggleBounceDurationVariance)
        bounceAnimation.repeatCount = HUGE
        
        //Apply animations to view
        UIView.animate(withDuration: 0) {
            view.layer.add(rotationAnim, forKey: "rotation")
            view.layer.add(bounceAnimation, forKey: "bounce")
            view.transform = .identity
        }
    }
    
    func stopWiggle(for view: UIView){ view.layer.removeAllAnimations() }
    
    //---------------------------------------------------------------------------------------------------------
    // MARK: -  ALERT
    //---------------------------------------------------------------------------------------------------------
    //-----------------------------------------GENERAL---------------------------------------------------------
    //push a alert with an button to triggle an action
    func pushAlertWithAction(alertTitle: String?, alertMessage: String?, buttonTitle: String?, buttonAction: @escaping () -> Void)
    {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: buttonTitle, style: .default) { (act) in buttonAction() }
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //push a alert with two options, one can be triggled to an action, the other one is for canceling the alert
    func pushAlertWithTwoOptions(alertTitle: String?, alertMessage: String?, actionTitle: String?, action: @escaping () -> Void)
    {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: actionTitle, style: .default) { (act) in
            action()
        }
        let alertAction2 = UIAlertAction(title: Constants.ok, style: .default, handler: nil)
        alertController.addAction(alertAction)
        alertController.addAction(alertAction2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //-----------------------------------------SPECIFIC--------------------------------------------------------
    //push a alert for simultaneously login
    func pushAlertForSimultaneouslyLogin(buttonAction action: @escaping () -> Void) {
        pushAlertWithAction(alertTitle: Constants.oops, alertMessage: Constants.simultaneouslyLoginMessage, buttonTitle: Constants.simultaneouslyLoginActionTitle, buttonAction: action)
    }
    
    //push a alert for reminding users to verify their email
    func pushAlertForEmailVerificationReminder() {
        pushAlertWithTwoOptions(alertTitle: Constants.emailVerificationTitle, alertMessage: Constants.emailVerificationMessage, actionTitle: Constants.sendEmailVerificationActionTitle) { self.sendEmailVerification() }
    }
    
    //push a alert for asking users to reauthenticate
    func pushAlertForReauthentication(buttonAction: @escaping (String?) -> Void)
    {
        let alertController = UIAlertController(title: Constants.reauthenticationTitle, message: Constants.reauthenticationMessage, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { (firstTextField) in
            firstTextField.placeholder = Constants.passwordTextFieldPlaceholder
            firstTextField.isSecureTextEntry = true
        })
        let alertAction = UIAlertAction(title: Constants.submit, style: .default) { (act) in
            buttonAction(alertController.textFields?.first?.text)
        }
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
