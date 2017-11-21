//
//  NGroupsCollectionViewCell.swift
//  Managee
//
//  Created by Fan Wu on 12/22/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

protocol MyGroupsCollectionViewCellDelegate { func deleteGroup(target: MyGroup) }

class MyGroupsCollectionViewCell: UICollectionViewCell {
    
    private struct BGColor {
        static let StatusTrue = UIColor.clear
        static let StatusFalse = UIColor.lightGray
    }
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var deleteGroupButton: UIButton!
    var delegate: MyGroupsCollectionViewCellDelegate?
    var myGroup: MyGroup? {
        didSet {
            //set to default setting first to remove reused cell setting
            groupNameLabel.text = myGroup?.name ?? Constants.unnamed
            groupImageView.image = #imageLiteral(resourceName: "defaultUser")
            if let url = myGroup?.imageURL {
                groupImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
            if myGroup?.status == true { backgroundColor = BGColor.StatusTrue } else { backgroundColor = BGColor.StatusFalse }
        }
    }
    
    @IBAction func deleteGroup() { if let targetGroup = myGroup { delegate?.deleteGroup(target: targetGroup) } }
}
