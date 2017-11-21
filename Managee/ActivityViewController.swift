//
//  ActivityViewController.swift
//  Managee
//
//  Created by Fan Wu on 1/2/17.
//  Copyright © 2017 8184. All rights reserved.
//

import UIKit
import SDWebImage

class ActivityViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    private struct ButtonTitle {
        static let signUp = "Sign Up"
        static let signOff = "Sign Off"
    }
    
    @IBOutlet weak var activityImageView: UIImageView!
    @IBOutlet weak var activityNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var signUpSignOffButton: UIButton!
    @IBOutlet weak var signUpMembersCollectionView: UICollectionView!
    var activity: Activity?
    private var imageIsReadyToUpload = false
    
    @IBAction func tapOnImageView(_ sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func activityNameTextFieldEditingChanged(_ sender: UITextField) {
        if activity?.name != sender.text && sender.text != "" { readyToSave(true) } else { if !imageIsReadyToUpload { readyToSave(false) } }
    }
    
    
    @IBAction func saveActivity(_ sender: UIBarButtonItem) {
        readyToSave(false)
        let oldName = activity?.name
        var compressedImageData: Data? = nil
        activity?.name = activityNameTextField.text
        //compress image
        if imageIsReadyToUpload {
            if let selectedImage = activityImageView.image { compressedImageData = UIImageJPEGRepresentation(selectedImage, 0.1) }
        }
        activity?.saveImageAndData(imageData: compressedImageData) { (errMsg) in
            if let m = errMsg {
                self.readyToSave(true)
                self.activity?.name = oldName
                self.activity?.imageURL = nil
                ProgressHud.message(to: self.view, msg: m)
            } else {
                //cache image
                if let imageData = compressedImageData, let image = UIImage(data: imageData) {
                    SDImageCache.shared().store(image, forKey: self.activity?.imageURL)
                }
            }
        }
    }
    
    @IBAction func signUpSignOff(_ sender: UIButton) {
        guard let member = curUser else { return }
        if sender.currentTitle == ButtonTitle.signUp {
            activity?.signUp(by: member) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
        } else {
            activity?.signOff(by: member) { (errMsg) in if let m = errMsg { ProgressHud.message(to: self.view, msg: m) } }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityNameTextField.text = activity?.name ?? Constants.unnamed
        if let url = activity?.imageURL {
            activityImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetCollectionView()
        setUpSignUpMemberIDsObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activity?.removeSignUpMemberIDsObserver()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage { activityImageView.image = selectedImage }
        imageIsReadyToUpload = true
        readyToSave(true)
        dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------COLLECTION VIEW---------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activity?.signUpMembers.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MStoryboard.memberCellIdentifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let memberCell = cell as! ActivityCollectionViewCell
        memberCell.member = activity?.signUpMembers[indexPath.row]
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func resetCollectionView() {
        activity?.signUpMembers.removeAll()
        signUpMembersCollectionView.reloadData()
    }
    
    private func setUpSignUpMemberIDsObserver() {
        ProgressHud.processingWithDuration(to: self.view)
        activity?.setUpSignUpMemberIDsObserver { (evenType, index) in
            if evenType == .added {
                ProgressHud.hideProcessing(to: self.view)
                self.insertItemForCollectionView(collectionView: self.signUpMembersCollectionView, at: index)
                self.updateSignUpSignOffButton()
            }
            if evenType == .removed {
                self.deleteItemForCollectionView(collectionView: self.signUpMembersCollectionView, at: index)
                self.updateSignUpSignOffButton()
            }
        }
    }
    
    private func updateSignUpSignOffButton() {
        if activity?.signUpMembers.contains(where: { $0.uid == curUser?.uid }) == true {
            signUpSignOffButton.setTitle(ButtonTitle.signOff, for: .normal)
        } else { signUpSignOffButton.setTitle(ButtonTitle.signUp, for: .normal) }
    }
    
    private func readyToSave (_ ready: Bool) { saveButton.isEnabled = ready ? true : false }
}
