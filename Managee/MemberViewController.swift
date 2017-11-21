//
//  MemberViewController.swift
//  Managee
//
//  Created by Fan Wu on 1/22/17.
//  Copyright © 2017 8184. All rights reserved.
//

import UIKit

class MemberViewController: UIViewController {
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var memberNameLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var assignOwnerButton: UIButton!
    var member: Member?
    
    @IBAction func accept() {
        guard let m = member else { return }
        m.status = true
        member?.ofGroup.accept(requestFrom: m) { (errMsg) in
            if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func reject() {
        guard let m = member else { return }
        member?.ofGroup.remove(member: m) { (errMsg) in
            if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func assignOwner() {
        assignOwnerButton.isEnabled = false
        guard let m = member else { return }
        member?.ofGroup.assign(nextCreater: m) { (errMsg) in
            if let m = errMsg {
                self.assignOwnerButton.isEnabled = true
                ProgressHud.message(to: self.view, msg: m)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memberNameLabel.text = member?.name ?? Constants.unnamed
        if let url = member?.imageURL {
            memberImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
        }
        if member?.ofGroup.currentUserIsManager == true && member?.status == false {
            acceptButton.isEnabled = true
            rejectButton.isEnabled = true
        }
        if member?.ofGroup.createrUid == curUser?.uid && member?.uid != curUser?.uid { assignOwnerButton.isEnabled = true }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        member?.ofGroup.setUpMemberOfCurrentUserObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        member?.ofGroup.removeMemberOfCurrentUserObserver()
    }
}
