//
//  Contact.swift
//  Close Friend
//
//  Created by user on 7/29/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit

class Contact {
    var name: String!
    var phone: [String?]
    var email: [String?]
    var image: UIImage?
    
    static var importedContactsIDs:[(String,String)] = []
    
    init(name: String, phone: [String?], email: [String?], image: UIImage?) {
        self.name = name
        self.phone = phone
        self.email = email
        self.image = image
    }
    
}
