//
//  ContactDetailsVC.swift
//  Close Friend
//
//  Created by user on 7/31/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit
import MessageUI

extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.height / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

class ContactDetailsVC: UIViewController, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var phoneBtn: UIButton!
    @IBOutlet weak var image: UIImageView!
    
    var titleString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        phoneBtn.setTitle(titleString, for: .normal)
        image.setRounded()
    }
   
    @IBAction func phoneTapped(_ sender: UIButton) {
    
//        if (MFMessageComposeViewController.canSendText()) {
//            let controller = MFMessageComposeViewController()
//            controller.body = "Message Body"
//            controller.recipients = [(phoneBtn.titleLabel?.text!)!]
//            controller.messageComposeDelegate = self
//            self.present(controller, animated: true, completion: nil)
//        }
        
        guard let number = URL(string: "tel://" + (phoneBtn.titleLabel?.text!)!) else { return }
        UIApplication.shared.open(number)
    }
    
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
}
