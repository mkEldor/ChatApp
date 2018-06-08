//
//  ViewController.swift
//  MyChatProject
//
//  Created by Аскар on 22.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Firebase



class MessagesController: UITableViewController {
    var loginController: LoginController?
    var messages = [Message]()
    var messagesDectionary = [String: Message]()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain,
                                                           target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "paper_plane"), style: .plain,
                                                            target: self, action: #selector(handleMessage))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        checkUserIsLoggedIn()
        observeUserMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        message.counterOfNotWrittenMessages = 0
        
        tableView.reloadData()
        guard let chatPartnerId = message.chatPartnerId() else {return}
        let ref = Database.database().reference().child("user").child(chatPartnerId)
        ref.observeSingleEvent(of: .value) { (snapshot) in
            print(snapshot)
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let user = MyUser()
                user.email = dictionary["email"] as? String
                user.id = chatPartnerId
                user.name = dictionary["name"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                
                self.showChatControllerForUser(user: user, indexPath: indexPath)
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        cell.message = messages[indexPath.row]
        return cell
    }
   
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func observeUserMessages(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded) { (snapshot) in
            let userId = snapshot.key
            var counterOfNotWrittenMessages = 0
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                
                if let value = snapshot.value as? Int{
                    if value == 0{
                        counterOfNotWrittenMessages += 1
                    }
                }
                let messagesRef = Database.database().reference().child("messages").child(messageId)
                messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dictionary = snapshot.value as? [String : AnyObject]{
                        let message = Message()
                        message.fromId = dictionary["fromId"] as? String
                        message.toId = dictionary["toId"] as? String
                        message.text = dictionary["text"] as? String
                        message.timestamp = dictionary["timestamp"] as? Int
                        
                        message.counterOfNotWrittenMessages = counterOfNotWrittenMessages
                        print("Here is counter \(counterOfNotWrittenMessages)")
                        if let chatPartnerId = message.chatPartnerId(){
                            self.messagesDectionary[chatPartnerId] = message
                        }
                        self.attemptReloadOfData()
                    }
                })
                
            }, withCancel: nil)
        }
    }
    
    private func attemptReloadOfData(){
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReloadTable(){
        self.messages = Array(self.messagesDectionary.values)
        self.messages.sort(by: { (m1, m2) -> Bool in
            return m1.timestamp! > m2.timestamp!
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func checkUserIsLoggedIn(){
        if Auth.auth().currentUser == nil{
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
        else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    func fetchUserAndSetupNavBarTitle(){
        print("fetchUserAndSetupNavBarTitle")
        let ref = Database.database().reference()
        Auth.auth().addStateDidChangeListener(){
            (auth, user) in
            if let email = Auth.auth().currentUser?.email{
                self.navigationItem.title = email
            }
            if let userID = Auth.auth().currentUser?.uid{
                print(userID)
                
                ref.child("user").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    if let value = value{
                        let user = MyUser()
                        user.email = value["email"] as? String
                        user.name = value["name"] as? String
                        user.profileImageUrl = value["profileImageUrl"] as? String
                        user.id = snapshot.key
                        print("Here is username")
                        print(user.name as Any)
                        self.setupNavBarWithUser(user: user)
                        self.messagesDectionary = [:]
                        self.messages = []
                        self.observeUserMessages()
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    func setupNavBarWithUser(user: MyUser){
        let titleView = UIView(frame: CGRect(x: 20, y: 10, width: 200, height: 24))
        titleView.isUserInteractionEnabled = true
        self.navigationItem.titleView = titleView
        self.navigationItem.titleView?.isUserInteractionEnabled = true
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let profileImageUrl = user.profileImageUrl{
            profileImageView.loadImageUsingKingfisherWithUrlString(urlString: profileImageUrl)
        }
        containerView.addSubview(profileImageView)
        
        profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let label = UILabel()
        label.text = user.name
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        
        label.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8).isActive = true
        label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        label.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
    }
    func showChatControllerForUser(user: MyUser, indexPath: IndexPath){
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    @objc func handleMessage(){
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController.init(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    @objc func handleLogout(){
        loginController = LoginController()
        loginController?.messagesController = self
        do {
            try Auth.auth().signOut()
        } catch let error {
            print(error as Any)
        }
        
        present(loginController!, animated: true, completion: nil)
    }
    
}



