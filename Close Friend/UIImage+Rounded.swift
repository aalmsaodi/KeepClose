//
//  UIImage+Rounded.swift
//  Close Friend
//
//  Created by user on 8/1/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.height / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}
