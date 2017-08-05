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
    var jobTitle: String?
    
    static var importedContactsIDs:[(String,String)] = []
    
    init() {
        self.name = ""
        self.phone = []
        self.email = []
        self.image = nil
        self.jobTitle = ""
    }
    
    init(name: String, phone: [String?], email: [String?], image: UIImage?, job: String?) {
        self.name = name
        self.phone = phone
        self.email = email
        self.image = image
        self.jobTitle = job
    }
    
}
