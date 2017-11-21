//
//  MyGroupCollectionViewCell.swift
//  Managee
//
//  Created by Fan Wu on 1/1/17.
//  Copyright © 2017 8184. All rights reserved.
//

import UIKit

protocol MyGroupCollectionViewCellDelegate { func deleteActivity(target: Activity) }

class MyGroupCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityImageView: UIImageView!
    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var deleteActivityButton: UIButton!
    var delegate: MyGroupCollectionViewCellDelegate?
    var activity: Activity? {
        didSet {
            //set to default setting first to remove reused cell setting
            activityNameLabel.text = activity?.name ?? Constants.unnamed
            activityImageView.image = #imageLiteral(resourceName: "defaultUser")
            if let url = activity?.imageURL {
                activityImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
    
    @IBAction func deleteActivity() { if let targetActivity = activity { delegate?.deleteActivity(target: targetActivity) } }
}
