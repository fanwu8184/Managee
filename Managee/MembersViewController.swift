//
//  MembersViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/27/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit

class MembersViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MembersCollectionViewCellDelegate {
    
    private struct CellLayer {
        static let selectedBorderWidth = CGFloat(2.5)
        static let borderColor = UIColor.blue.cgColor
        static let unselectedBorderWidth = CGFloat(0)
    }
    
    @IBOutlet weak var membersCollectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    private var readyToSelect = false
    var myGroup: MyGroup?
    
    @IBAction func doneEdit(_ sender: UIBarButtonItem) {
        doneButton.isEnabled = false
        readyToSelect = false
        membersCollectionView.reloadData()
        myGroup?.saveMembersData { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        membersCollectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetCollectionView()
        myGroup?.setUpMemberOfCurrentUserObserver()
        setUpMembersObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myGroup?.removeMemberOfCurrentUserObserver()
        myGroup?.removeMembersObserver()
    }
    
    func deleteMember(target: Member) {
        myGroup?.remove(member: target) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    func longPressAction(_ sender: UILongPressGestureRecognizer) {
        if myGroup?.currentUserIsManager == true || myGroup?.createrUid == curUser?.uid {
            readyToSelect = true
            doneButton.isEnabled = true
            for cell in membersCollectionView.visibleCells {
                startWiggle(for: cell)
                let memberCell = cell as! MembersCollectionViewCell
                memberCell.deleteMemberButton.isHidden = !doneButton.isEnabled
            }
        } else { ProgressHud.message(to: self.view, msg: Constants.noPermission) }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let memberVC = segue.destination as? MemberViewController {
            memberVC.member = sender as? Member
        }
    }
    
    //-----------------------------------------COLLECTION VIEW---------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myGroup?.members.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MStoryboard.memberCellIdentifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        cell.addGestureRecognizer(longPress)
        if doneButton.isEnabled { startWiggle(for: cell) }
        
        let memberCell = cell as! MembersCollectionViewCell
        memberCell.member = myGroup?.members[indexPath.row]
        memberCell.deleteMemberButton.isHidden = !doneButton.isEnabled
        memberCell.delegate = self
        if memberCell.member?.isManager == true {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            updateCellUI(of: memberCell, isSelected: true)
        } else { updateCellUI(of: memberCell, isSelected: false) }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let member = myGroup?.members[indexPath.row] else { return }
        if readyToSelect {
            //if member status is false then set to true. Otherwise, set the member isManager true
            if member.status == false {
                member.status = true
                myGroup?.accept(requestFrom: member) { (errMsg) in
                    if let m = errMsg {
                        member.status = false
                        ProgressHud.message(to: self.view, msg: m)
                    }
                }
            } else {
                member.isManager = true
                guard let cell = collectionView.cellForItem(at: indexPath) else { return }
                updateCellUI(of: cell, isSelected: true)
            }
        } else { performSegue(withIdentifier: MStoryboard.segueMember, sender: member) }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if readyToSelect {
            myGroup?.members[indexPath.row].isManager = false
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }
            updateCellUI(of: cell, isSelected: false)
        }
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func resetCollectionView() {
        myGroup?.members.removeAll()
        membersCollectionView.reloadData()
    }
    
    private func setUpMembersObserver() {
        ProgressHud.processing(to: self.view)
        myGroup?.setUpMembersObserver { (evenType, index) in
            if evenType == .added {
                ProgressHud.hideProcessing(to: self.view)
                self.insertItemForCollectionView(collectionView: self.membersCollectionView, at: index)
            }
            if evenType == .removed { self.deleteItemForCollectionView(collectionView: self.membersCollectionView, at: index) }
            if evenType == .changed {
                let indexPath = IndexPath(row: index, section: 0)
                self.membersCollectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    private func updateCellUI(of cell: UICollectionViewCell, isSelected: Bool) {
        if isSelected {
            cell.layer.borderWidth = CellLayer.selectedBorderWidth
            cell.layer.borderColor = CellLayer.borderColor
        } else { cell.layer.borderWidth = CellLayer.unselectedBorderWidth }
    }
}
