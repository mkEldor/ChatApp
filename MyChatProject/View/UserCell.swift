//
//  UserCell.swift
//  MyChatProject
//
//  Created by Аскар on 24.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell{
    
    var message: Message?{
        didSet{
            
            setupNameAndProfileImage()
            print(message?.text as Any)
            if let nonOptionalText = message?.text{
                if nonOptionalText.count > 25{
                    var text = nonOptionalText[String.Index.init(encodedOffset: 0)..<String.Index.init(encodedOffset: 25)]
                    text += "..."
                    self.detailTextLabel?.text = String(text)
                }
                else {
                    self.detailTextLabel?.text = nonOptionalText
                }
                
            }
            else {
                self.detailTextLabel?.text = "image.jpeg"
            }
            if let countOfMessage = message?.counterOfNotWrittenMessages{
                if countOfMessage > 0{
                    counterView.isHidden = false
                    notWrittenMessagesLabel.text = "\(countOfMessage)"
                }
            }
            
            
            if let seconds = message?.timestamp{
                let timestampDate = NSDate.init(timeIntervalSince1970: Double(seconds))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                
                
                self.timeLabel.text = dateFormatter.string(from: timestampDate as Date)
            }
        }
    }
    
    private func setupNameAndProfileImage(){
        if let id = message?.chatPartnerId(){
            let ref = Database.database().reference().child("user").child(id)
            ref.observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    self.textLabel?.text = dictionary["name"] as? String
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String{
                        self.profileImageView.loadImageUsingKingfisherWithUrlString(urlString: profileImageUrl)
                    }
                }
            }, withCancel: nil)
        }
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect.init(x: 80, y: textLabel!.frame.origin.y - 4, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect.init(x: 80, y: detailTextLabel!.frame.origin.y, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let counterView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.backgroundColor = ChatMessageCell.blueColor
        return view
    }()
    let notWrittenMessagesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white

        label.text = "99+"
        
        
        return label
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage.init(named: "second")
        imageView.layer.cornerRadius = 32
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        addSubview(profileImageView)
        addSubview(timeLabel)
        addSubview(counterView)
        counterView.addSubview(notWrittenMessagesLabel)
        
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        timeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
        
        counterView.centerXAnchor.constraint(equalTo: timeLabel.centerXAnchor).isActive = true
        counterView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4).isActive = true
        counterView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        counterView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        notWrittenMessagesLabel.centerXAnchor.constraint(equalTo: counterView.centerXAnchor).isActive = true
        notWrittenMessagesLabel.centerYAnchor.constraint(equalTo: counterView.centerYAnchor).isActive = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



