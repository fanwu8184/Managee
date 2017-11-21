//
//  MembersCollectionViewCell.swift
//  Managee
//
//  Created by Fan Wu on 12/27/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

protocol MembersCollectionViewCellDelegate { func deleteMember(target: Member) }

class MembersCollectionViewCell: UICollectionViewCell {
    
    private struct BGColor {
        static let StatusTrue = UIColor.clear
        static let StatusFalse = UIColor.lightGray
    }
    
    @IBOutlet weak var deleteMemberButton: UIButton!
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var memberNameLabel: UILabel!
    var delegate: MembersCollectionViewCellDelegate?
    var member: Member? {
        didSet {
            //set to default setting first to remove reused cell setting
            memberNameLabel.text = member?.name ?? Constants.unnamed
            memberImageView.image = #imageLiteral(resourceName: "defaultUser")
            if let url = member?.imageURL {
                memberImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
            if member?.status == true { backgroundColor = BGColor.StatusTrue } else { backgroundColor = BGColor.StatusFalse }
        }
    }
    
    @IBAction func deleteMember() { if let targetMember = member { delegate?.deleteMember(target: targetMember) } }
}
