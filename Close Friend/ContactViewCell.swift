//
//  ContactViewCell.swift
//  Close Friend
//
//  Created by user on 7/29/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit

class ContactViewCell: UITableViewCell {

    @IBOutlet weak var contactPic: UIImageView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var periodStr: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
