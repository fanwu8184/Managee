//
//  UserProfileViewController.swift
//  Managee
//
//  Created by Fan Wu on 12/6/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit
import SDWebImage

class UserProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    private var imageIsReadyToUpload = false
    
    @IBAction func tapOnImageView(_ sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    //if current user info. does not change, the save button will be off
    @IBAction func nameTextFieldEditingChanged(_ sender: UITextField) {
        if curUser?.name != sender.text && sender.text != "" { readyToSave(true) } else { if !imageIsReadyToUpload { readyToSave(false) } }
    }

    //save current user info.
    @IBAction func save(_ sender: UIBarButtonItem) {
        readyToSave(false)
        let oldName = curUser?.name
        var compressedImageData: Data? = nil
        curUser?.name = userNameTextField.text
        if imageIsReadyToUpload {
            if let selectedImage = userImageView.image { compressedImageData = UIImageJPEGRepresentation(selectedImage, 0.1) }
        }
        curUser?.saveImageAndProfileData(imageData: compressedImageData) { (errMsg) in
            if let m = errMsg {
                self.readyToSave(true)
                curUser?.name = oldName
                curUser?.imageURL = nil
                ProgressHud.message(to: self.view, msg: m)
            } else {
                //cache image
                if let imageData = compressedImageData, let image = UIImage(data: imageData) {
                    SDImageCache.shared().store(image, forKey: curUser?.imageURL)
                }
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
        updateUI()
    }
    
    override func loadData() {
        if curUser != nil {
            ProgressHud.processing(to: self.view, block: true)
            curUser?.loadProfileData {
                ProgressHud.hideProcessing(to: self.view)
                self.updateUI()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userNameTextField.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage { userImageView.image = selectedImage }
        imageIsReadyToUpload = true
        readyToSave(true)
        dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------PRIVATE---------------------------------------------------------
    private func updateUI() {
        //set to default setting first to remove previous setting
        userImageView.image = #imageLiteral(resourceName: "defaultUser")
        userNameTextField.text = ""
        if curUser != nil {
            userNameTextField.text = curUser?.name ?? Constants.unnamed
            if let url = curUser?.imageURL {
                userImageView.sd_setImage(with: URL(string: url), placeholderImage: #imageLiteral(resourceName: "downloading"), options: .progressiveDownload)
            }
        }
    }
    
    //switch the save button on if the user info. is ready to be saved
    private func readyToSave (_ ready: Bool) { saveButton.isEnabled = ready ? true : false }
}
