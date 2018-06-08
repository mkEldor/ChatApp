//
//  NewMessageViewController.swift
//  MyChatProject
//
//  Created by Аскар on 22.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class NewMessageController: UITableViewController {
    let cellId = "cellId"
    var users = [MyUser]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUsers()
        
    }
    
    func fetchUsers() {
        print("blablablablasdnjn sc xcnsd c")
        let ref = Database.database().reference().child("user")
        ref.observe(.childAdded, with: {
            (snapshot) in
            if let userDict = snapshot.value as? [String : AnyObject]{
                if let name = userDict["name"] as? String, let email = userDict["email"] as? String, let profileImageUrl = userDict["profileImageUrl"] as? String{
                    let user = MyUser()
                    user.name = name
                    user.email = email
                    user.profileImageUrl = profileImageUrl
                    user.id = snapshot.key
                    if Auth.auth().currentUser?.uid != user.id {
                        self.users.append(user)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
            }
            
        }, withCancel: nil)
        
    }
    
    @objc func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell

        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let profileImage = user.profileImageUrl{
            cell.profileImageView.loadImageUsingKingfisherWithUrlString(urlString: profileImage)
        }
        
        
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
        
    }
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: {
            print("Dissmiss completed")
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user, indexPath: IndexPath.init(row: -1, section: 0))
        })
    }

}
