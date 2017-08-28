//
//  NotificationCell.swift
//  Close Friend
//
//  Created by user on 8/8/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var pic: UIImageView!
    @IBOutlet weak var name: CopyableUILabel!
    @IBOutlet weak var job: UILabel!
    @IBOutlet weak var callBtn: UIButton!
    @IBOutlet weak var textBtn: UIButton!
    @IBOutlet weak var emailBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        pic.layer.cornerRadius = 5
        pic.clipsToBounds = true
        callBtn.layer.cornerRadius = 5
        textBtn.layer.cornerRadius = 5
        emailBtn.layer.cornerRadius = 5

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
