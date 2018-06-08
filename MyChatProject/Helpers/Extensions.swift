//
//  Extensions.swift
//  MyChatProject
//
//  Created by Аскар on 23.03.2018.
//  Copyright © 2018 askar.ulubayev168. All rights reserved.
//

import UIKit
import Kingfisher

let imageCache = NSCache<AnyObject, AnyObject>()


extension UIImageView{
    func loadImageUsingKingfisherWithUrlString(urlString: String){
        self.image = nil
        
        // check cache for image
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? ImageResource{
            self.kf.setImage(with: cachedImage)
            return
        }
        
        DispatchQueue.main.async {
            let url = URL.init(string: urlString)
            let resource = ImageResource(downloadURL: url!)
            imageCache.setObject(resource as AnyObject, forKey: url as AnyObject)
            self.kf.setImage(with: resource)
        }
    }
    
}
