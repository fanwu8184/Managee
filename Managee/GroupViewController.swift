//
//  GroupViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/28/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class GroupViewController: UIViewController {
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var createrImageView: UIImageView!
    @IBOutlet weak var createrNameLabel: UILabel!
    @IBOutlet weak var joinButton: UIBarButtonItem!
    var group: Group?
    
    @IBAction func join(_ sender: UIBarButtonItem) {
        guard let g = group else { return }
        //this way will prevent multi-join
        joinButton.isEnabled = false
        curUser?.join(into: g) { (errMsg) in
            if let m = errMsg {
                self.joinButton.isEnabled = true
                ProgressHud.message(to: self.view, msg: m)
            } else { ProgressHud.message(to: self.view, msgTitle: Constants.great, msg: Constants.joinGroup) }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateGroupUI()
        updateCreaterUI()
        updateJoinButton()
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func updateGroupUI() {
        groupNameLabel.text = group?.name ?? Constants.unnamed
        if let url = group?.imageURL {
            groupImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
        }
    }
    
    private func updateCreaterUI() {
        guard let g = group else { return }
        let creater = User(key: g.createrUid)
        creater.loadProfileData {
            self.createrNameLabel.text = creater.name ?? Constants.unnamed
            if let url = creater.imageURL {
                self.createrImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
    
    private func updateJoinButton() {
        guard let user = curUser else { return }
        group?.checkMemberStatus(of: user) { (isMember) in
            if isMember { self.joinButton.isEnabled = false } else { self.joinButton.isEnabled = true }
        }
    }
}
