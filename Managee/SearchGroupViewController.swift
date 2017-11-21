//
//  SearchGrooupViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/26/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class SearchGroupViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var resultCollectionView: UICollectionView!
    private var result = [Group]()
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        guard let name = searchBar.text else { return }
        ProgressHud.processingWithDuration(to: self.view)
        dataService.searchGroupByName(searchContent: name) { (gid, uid, profile) in
            ProgressHud.hideProcessing(to: self.view)
            guard let createrUid = uid else { return }
            let group = Group(key: gid, uid: createrUid)
            group.updateProfileData(value: profile)
            self.result.append(group)
            self.resultCollectionView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let groupVC = segue.destination as? GroupViewController,
            let indexPath = resultCollectionView.indexPathsForSelectedItems?.first {
            groupVC.group = result[indexPath.row]
        }
    }
    
    //-----------------------------------------COLLECTION VIEW---------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return result.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MStoryboard.searchCellIdentifier, for: indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let resultCell = cell as! SearchGroupCollectionViewCell
        resultCell.group = result[indexPath.row]
    }
}
