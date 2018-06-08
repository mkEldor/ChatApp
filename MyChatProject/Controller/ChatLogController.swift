//
//  ChatLogController.swift
//  MyChatProject
//
//  Created by Аскар on 24.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVKit

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var messagesController: MessagesController?
    let cellId = "cellId"
    var indexPath: IndexPath?
    
    var user: MyUser? {
        didSet{
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    var messagesFromMessagesController: [Message]?
    var messages = [Message]()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let messagesController = MessagesController()
        
        let navigationController = UINavigationController.init(rootViewController: messagesController)
        
        present(navigationController, animated: false, completion: nil)
    }
    
    
    func observeMessages(){
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {return}
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(toId).updateChildValues([messageId: 1])

        }
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {return}
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.toId = dictionary["toId"] as? String
                message.text = dictionary["text"] as? String
                message.timestamp = dictionary["timestamp"] as? Int
                message.imageUrl = dictionary["imageUrl"] as? String
                message.imageWidth = dictionary["imageWidth"] as? Int
                message.imageHeight = dictionary["imageHeight"] as? Int
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    
                    self.collectionView?.scrollToItem(at: IndexPath.init(item: self.messages.count-1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter message..."
        tf.delegate = self
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets.init(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        
        setupKeyboardObservers()
    }
    
  
    
    lazy var inputContainer: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIButton()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.setImage(UIImage.init(named: "picture"), for: .normal)
        uploadImageView.addTarget(self, action: #selector(handleUploadTap), for: .touchUpInside)
        
        containerView.addSubview(uploadImageView)
        
        uploadImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        inputTextField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: 0).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let seperatorLine = UIView()
        seperatorLine.backgroundColor = UIColor.init(red: 220, green: 220, blue: 220)
        seperatorLine.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(seperatorLine)
        
        seperatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        seperatorLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        seperatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    @objc func handleUploadTap(){
  
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL{
            handleVideoSelectedForUrl(url: videoUrl)
        }
        else {
            handleImageSelectedForInfo(info: info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    
    private func handleImageSelectedForInfo(info: [String: Any]){
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
            print(editedImage.size)
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            print(originalImage.size)
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker{
            uploadToFirebaseStorage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessagesWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    private func handleVideoSelectedForUrl(url: NSURL){
        let fileName = "someFilename.mov"
        let uploadTask = Storage.storage().reference().child(fileName).putFile(from: url as URL, metadata: nil, completion: { (metadata, error) in
            if error != nil{
                print("Some error with uploading")
                return
            }
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForVideoUrl(videoUrl: url){
                    let properties = ["imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl] as [String : Any]
                    self.sendMessageWithProperties(properties: properties)
                }
                
                let properties = ["videoUrl": videoUrl] as [String : Any]
                self.sendMessageWithProperties(properties: properties)
            }
        })
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnit = snapshot.progress?.completedUnitCount{
                self.navigationItem.title = String(completedUnit)
            }
        }
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForVideoUrl(videoUrl: NSURL) -> UIImage?{
        let asset = AVAsset.init(url: videoUrl as URL)
        let imageGenerator = AVAssetImageGenerator.init(asset: asset)
        do{
            let thumbnailCgImage = try imageGenerator.copyCGImage(at: CMTime.init(value: 1, timescale: 60), actualTime: nil)
            return UIImage.init(cgImage: thumbnailCgImage)
        }
        catch let error{
            print(error)
        }
        
        return nil
        
    }
    
    private func uploadToFirebaseStorage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()){
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print("error with uploading image")
                    return
                }
                if let imageUrl = metadata?.downloadURL()?.absoluteString{
                    completion(imageUrl)
                    
                }
            })
            
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView?{
        get {
            return inputContainer
        }
    }
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    func setupKeyboardObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    @objc func handleKeyboardDidShow(){
        if messages.count > 0{
            collectionView?.scrollToItem(at: IndexPath.init(row: messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyBoardWillHide(notification: NSNotification){
        containerViewBottomAnchor?.constant = 0
        
        guard let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }
        let duration = keyboardDuration.doubleValue
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
        
        
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification){
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardHeight: CGFloat = keyboardFrame.cgRectValue.height
        containerViewBottomAnchor?.constant = -keyboardHeight
        
        guard let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }
        let duration = keyboardDuration.doubleValue
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        setupCell(cell: cell, message: message)
        if let text = message.text{
            cell.bubleWidthConstraint?.constant = estimateFrameForText(text: text).width + 24
            cell.textView.isHidden = false
        }
        else if message.imageUrl != nil{
            cell.bubleWidthConstraint?.constant = 200
            cell.textView.isHidden = true
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message){
        if let profileImageUrl = self.user?.profileImageUrl{
            cell.profileImageView.loadImageUsingKingfisherWithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl{
            cell.messageImageView.loadImageUsingKingfisherWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
            
        }
        else {
            cell.messageImageView.isHidden = true
            
        }
        
        if message.fromId == Auth.auth().currentUser?.uid{
            cell.bubbleView.backgroundColor = UIColor.init(red: 0, green: 137, blue: 240)
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            
            cell.bubbleRightConstraint?.isActive = true
            cell.bubbleLeftConstraint?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = UIColor.init(red: 240, green: 240, blue: 240)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            
            cell.bubbleRightConstraint?.isActive = false
            cell.bubbleLeftConstraint?.isActive = true
            
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        //var width: CGFloat = 200
        
        if let _ = messages[indexPath.row].imageUrl{
            if let imageWidth = messages[indexPath.row].imageWidth, let imageHeight = messages[indexPath.row].imageHeight{
                height = (CGFloat(imageHeight) / CGFloat(imageWidth) * 200)
            }
        }
        
        if let text = messages[indexPath.row].text{
            height = estimateFrameForText(text: text).height + 20
        }
        let width = UIScreen.main.bounds.width
        return CGSize.init(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString.init(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    
    @objc func handleSend(){
        if let text = inputTextField.text {
            if !text.isEmpty{
                print(inputTextField.text as Any)
                let properties = ["text": text] as [String : Any]
                sendMessageWithProperties(properties: properties)
                inputTextField.text = ""
            }
        }
    }
    
    private func sendMessagesWithImageUrl(imageUrl: String, image: UIImage){
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: Any]){
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser?.uid
        let timestamp: Int = Int(NSDate().timeIntervalSince1970)
        var values = ["fromId": fromId as Any, "toId": toId, "timestamp": timestamp] as [String : Any]
        
        properties.forEach { (arg) in
            
            let (key, value) = arg
            values[key] = value
        }
        
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil{
                print("Error")
                return
            }
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId!).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId!)
            recipientUserMessageRef.updateChildValues([messageId: 0])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForImageView(startingimageView: UIImageView){
        print("Performing zoom of imageview")
        self.startingImageView = startingimageView
        self.startingImageView?.isHidden = true
        startingFrame = startingimageView.superview?.convert(startingimageView.frame, to: nil)
        if let startingFrame = startingFrame{
            let zoomingImageView = UIImageView.init(frame: startingFrame)
            zoomingImageView.image = startingimageView.image
            zoomingImageView.isUserInteractionEnabled = true
            zoomingImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleZoomOut)))
            if let keyWindow = UIApplication.shared.keyWindow{
                
                blackBackgroundView = UIView.init(frame: keyWindow.frame)
                blackBackgroundView?.backgroundColor = .black
                blackBackgroundView?.alpha = 0
                keyWindow.addSubview(blackBackgroundView!)
                keyWindow.addSubview(zoomingImageView)
                
                
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    let height = startingFrame.height/startingFrame.width * keyWindow.frame.width
                    zoomingImageView.frame = CGRect.init(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                    zoomingImageView.center = keyWindow.center
                    self.blackBackgroundView?.alpha = 1
                    self.inputContainer.alpha = 0
                }, completion: nil)
            }
        }
    }
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer){
        if let zoomoutImageView = tapGesture.view as? UIImageView{
            
            zoomoutImageView.layer.cornerRadius = 10
            zoomoutImageView.layer.masksToBounds = true
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                zoomoutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainer.alpha = 1
            }, completion: { (isCompleted) in
                zoomoutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
}


