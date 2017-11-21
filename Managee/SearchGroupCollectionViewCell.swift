//
//  SearchGroupCollectionViewCell.swift
//  Managee
//
//  Created by Fan Wu on 12/27/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class SearchGroupCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    var group: Group? {
        didSet {
            //set to default setting first to remove reused cell setting
            groupNameLabel.text = group?.name
            groupImageView.image = #imageLiteral(resourceName: "defaultUser")
            if let url = group?.imageURL {
                groupImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
    
}
