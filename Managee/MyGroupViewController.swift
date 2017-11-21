//
//  GroupViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/22/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit
import SDWebImage

class MyGroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, MyGroupCollectionViewCellDelegate {
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var createrImageView: UIImageView!
    @IBOutlet weak var createrNameLabel: UILabel!
    @IBOutlet weak var activitiesCollectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIButton!
    var myGroup: MyGroup?
    private var imageIsReadyToUpload = false
    
    @IBAction func tapOnGroupImageView(_ sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage { groupImageView.image = selectedImage }
        imageIsReadyToUpload = true
        readyToSave(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func groupNameTextFieldEditingChanged(_ sender: UITextField) {
        if myGroup?.name != sender.text && sender.text != "" { readyToSave(true) } else { if !imageIsReadyToUpload { readyToSave(false) } }
    }

    @IBAction func saveGroup() {
        readyToSave(false)
        let oldName = myGroup?.name
        var compressedImageData: Data? = nil
        myGroup?.name = groupNameTextField.text
        //compress image
        if imageIsReadyToUpload {
            if let selectedImage = groupImageView.image { compressedImageData = UIImageJPEGRepresentation(selectedImage, 0.1) }
        }
        myGroup?.saveImageAndProfileData(imageData: compressedImageData) { (errMsg) in
            if let m = errMsg {
                self.readyToSave(true)
                self.myGroup?.name = oldName
                self.myGroup?.imageURL = nil
                ProgressHud.message(to: self.view, msg: m)
            } else {
                self.readyToSave(false)
                //cache image
                if let imageData = compressedImageData, let image = UIImage(data: imageData) {
                    SDImageCache.shared().store(image, forKey: self.myGroup?.imageURL)
                }
            }
        }
    }
    
    @IBAction func doneEdit() {
        doneButton.isEnabled = false
        activitiesCollectionView.reloadData()
    }
    
    
    @IBAction func addActivity() {
        myGroup?.createAid { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupNameTextField.delegate = self
        
        groupNameTextField.text = myGroup?.name ?? Constants.unnamed
        if let url = myGroup?.imageURL {
            groupImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetCollectionView()
        myGroup?.setUpMemberOfCurrentUserObserver()
        setUpCreaterUidObserver()
        setUpAidsObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myGroup?.removeMemberOfCurrentUserObserver()
        myGroup?.removeCreaterUidObserver()
        myGroup?.removeAidsObserver()
    }
    
    func deleteActivity(target: Activity) {
        myGroup?.removeAid(of: target) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
    }
    
    func longPressOnCells(_ sender: UILongPressGestureRecognizer) {
        doneButton.isEnabled = true
        for cell in activitiesCollectionView.visibleCells {
            startWiggle(for: cell)
            let activityCell = cell as! MyGroupCollectionViewCell
            activityCell.deleteActivityButton.isHidden = !doneButton.isEnabled
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        view.endEditing(true)
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        groupNameTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let membersVC = segue.destination as? MembersViewController {
            membersVC.myGroup = myGroup
        }
        if let activityVC = segue.destination as? ActivityViewController {
            activityVC.activity = sender as? Activity
        }
    }
    
    //-----------------------------------------COLLECTION VIEW---------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myGroup?.activities.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MStoryboard.activityCellIdentifier, for: indexPath) as UICollectionViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnCells))
        cell.addGestureRecognizer(longPress)
        if doneButton.isEnabled { startWiggle(for: cell) }
        
        let activityCell = cell as! MyGroupCollectionViewCell
        activityCell.deleteActivityButton.isHidden = !doneButton.isEnabled
        activityCell.activity = myGroup?.activities[indexPath.row]
        activityCell.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if myGroup?.currentUserStatus == true {
            performSegue(withIdentifier: MStoryboard.segueActivity, sender: myGroup?.activities[indexPath.row])
        } else { ProgressHud.message(to: self.view, msg: Constants.needApproval) }
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func resetCollectionView() {
        myGroup?.activities.removeAll()
        activitiesCollectionView.reloadData()
    }
    
    private func setUpCreaterUidObserver() {
        myGroup?.setUpCreaterUidObserver { (name, imageURL) in
            self.createrNameLabel.text = name ?? Constants.unnamed
            if let url = imageURL {
                self.createrImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
    
    private func setUpAidsObserver() {
        ProgressHud.processingWithDuration(to: self.view)
        myGroup?.setUpAidsObserver { (evenType, index) in
            if evenType == .added {
                ProgressHud.hideProcessing(to: self.view)
                self.insertItemForCollectionView(collectionView: self.activitiesCollectionView, at: index)
            }
            if evenType == .removed { self.deleteItemForCollectionView(collectionView: self.activitiesCollectionView, at: index) }
        }
    }
    
    //switch the save button on if the group info. is ready to be saved
    private func readyToSave (_ ready: Bool) { saveButton.isEnabled = ready ? true : false }
}
