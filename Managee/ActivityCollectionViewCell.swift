//
//  ActivityCollectionViewCell.swift
//  Managee
//
//  Created by Fan Wu on 1/23/17.
//  Copyright © 2017 8184. All rights reserved.
//

import UIKit

class ActivityCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var memberNameLabel: UILabel!
    var member: User? {
        didSet {
            //set to default setting first to remove reused cell setting
            memberNameLabel.text = member?.name ?? Constants.unnamed
            memberImageView.image = #imageLiteral(resourceName: "defaultUser")
            if let url = member?.imageURL {
                memberImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
}
