//
//  NGroupsViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/13/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class MyGroupsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MyGroupsCollectionViewCellDelegate {
    
    @IBOutlet weak var groupsCollectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    @IBAction func addGroup(_ sender: UIBarButtonItem) {
        guard let numberOfMyGroups = curUser?.myGroups.count else { return }
        curUser?.createGid(ord: numberOfMyGroups) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    func deleteGroup(target: MyGroup) {
        curUser?.removeGid(of: target) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    @IBAction func doneEdit(_ sender: UIBarButtonItem) {
        doneButton.isEnabled = false
        groupsCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestEmailVerification()
        resetCollectionView()
        setUpGidsObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        curUser?.removeGidsObserver()
    }
    
    func longPressAction(_ sender: UILongPressGestureRecognizer) {
        doneButton.isEnabled = true
        for cell in groupsCollectionView.visibleCells {
            startWiggle(for: cell)
            let groupCell = cell as! MyGroupsCollectionViewCell
            groupCell.deleteGroupButton.isHidden = !doneButton.isEnabled
        }
    }
    
    func panAction(_ sender: UIPanGestureRecognizer) {
        if doneButton.isEnabled {
            switch(sender.state) {
            case UIGestureRecognizerState.began:
                if let selectedIndexPath = groupsCollectionView.indexPathForItem(at: sender.location(in: groupsCollectionView)) {
                    groupsCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                }
            case UIGestureRecognizerState.changed:
                groupsCollectionView.updateInteractiveMovementTargetPosition(sender.location(in: groupsCollectionView))
            case UIGestureRecognizerState.ended:
                groupsCollectionView.endInteractiveMovement()
            default:
                groupsCollectionView.cancelInteractiveMovement()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let groupVC = segue.destination as? MyGroupViewController {
            if let indexPath = groupsCollectionView.indexPathsForSelectedItems?.first {
                groupVC.myGroup = curUser?.myGroups[indexPath.row]
            }
        }
    }
    
     //-----------------------------------------COLLECTION VIEW---------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return curUser?.myGroups.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MStoryboard.myGroupCellIdentifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        cell.addGestureRecognizer(longPress)
        cell.addGestureRecognizer(pan)
        if doneButton.isEnabled { startWiggle(for: cell) }
        
        let myGroupCell = cell as! MyGroupsCollectionViewCell
        myGroupCell.deleteGroupButton.isHidden = !doneButton.isEnabled
        myGroupCell.myGroup = curUser?.myGroups[indexPath.row]
        myGroupCell.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        curUser?.reorderMyGroups(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row) { (errMsg) in
            if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func resetCollectionView() {
        curUser?.myGroups.removeAll()
        self.groupsCollectionView.reloadData()
    }
    
    private func setUpGidsObserver() {
        if curUser != nil {
            let win = UIApplication.shared.windows.last!
            ProgressHud.processingWithDuration(to: win, block: true)
            curUser?.setUpGidsObserver { (evenType, index) in
                if evenType == .added {
                    ProgressHud.hideProcessing(to: self.view)
                    self.insertItemForCollectionView(collectionView: self.groupsCollectionView, at: index)
                }
                if evenType == .removed { self.deleteItemForCollectionView(collectionView: self.groupsCollectionView, at: index) }
                if evenType == .changed {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.groupsCollectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}
