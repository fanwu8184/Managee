//
//  MeTableViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/4/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit
import SDWebImage

class MeTableViewController: UITableViewController {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!

    @IBAction func logout(_ sender: UIBarButtonItem) {
        curUser?.logout()
        curUser = nil
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        requestEmailVerification()
    }
    
    override func loadData() {
        if curUser != nil {
            ProgressHud.processing(to: self.view, block: true)
            curUser?.loadProfileData {
                ProgressHud.hideProcessing(to: self.view)
                self.updateUI()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            let vc = segue.destination as? AccountManagementViewController
            vc?.segueIdentifier = identifier
        }
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func updateUI() {
        //set to default setting first to remove previous setting
        userImageView.image = #imageLiteral(resourceName: "defaultUser")
        userEmailLabel.text = curUser?.email
        userNameLabel.text = ""
        if curUser != nil {
            if let url = curUser?.imageURL {
                userImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
            userNameLabel.text = curUser?.name ?? Constants.unnamed
        }
    }
}
