//
//  ContactDetailsVC.swift
//  Close Friend
//
//  Created by user on 7/31/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit
import MessageUI


enum typeOfAction {
    case call
    case text
    case email
    case social
}

class ContactDetailsVC: UIViewController, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var fullNameLabel: CopyableUILabel!
    
    @IBOutlet weak var callBtn: UIButton!
    @IBOutlet weak var textBtn: UIButton!
    @IBOutlet weak var emailBtn: UIButton!
    var contactDetails = Contact()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image.setRounded()
        fullNameLabel.text = contactDetails.name
        
        if contactDetails.phone.count == 0 {callBtn.isHidden = true; textBtn.isHidden = true}
        if contactDetails.email.count == 0 {emailBtn.isHidden = true}

    }
    
    @IBAction func callTapped(_ sender: UIButton) {
    
        if contactDetails.phone.count == 1 {
            let cleanNum = String(contactDetails.phone.first!!.characters.filter { "0123456789".characters.contains($0) })
            guard let number = URL(string: ("tel://" + cleanNum)) else { return }
            UIApplication.shared.open(number)
            
        } else if contactDetails.phone.count > 1 {
            
            CustomActionOptions(type: .call)
        }
    }
    
    @IBAction func textTapped(_ sender: UIButton) {
        
        if (MFMessageComposeViewController.canSendText()) {
            
            if contactDetails.phone.count == 1 {
                
                let messageController = MFMessageComposeViewController()
                messageController.messageComposeDelegate = self
                
                let cleanNum = String(contactDetails.phone.first!!.characters.filter { "0123456789".characters.contains($0) })
                messageController.recipients = [cleanNum]
                
                self.present(messageController, animated: true, completion: nil)
                
            } else if contactDetails.phone.count > 1 {
                
                CustomActionOptions(type: .text)
            }
        }
    }

    
    @IBAction func emailTapped(_ sender: UIButton) {
        if (MFMailComposeViewController.canSendMail()) {
            
            if contactDetails.email.count == 1 {
                
                let mailController = MFMailComposeViewController()
                mailController.mailComposeDelegate = self
                
                mailController.setToRecipients(contactDetails.email as? [String])
                self.present(mailController, animated: true, completion: nil)
                
            } else if contactDetails.email.count > 1 {
                
                CustomActionOptions(type: .email)
            }
            
        } else {
            
            let alert = UIAlertController(title: "Make sure that you have an Email account setup correctly on this device", message: "", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }

    
// MARK: - Handiling multiple contact actions
    func CustomActionOptions(type:typeOfAction){
        
        let alert = UIAlertController(title: "Please choose one", message: "", preferredStyle: .alert)
        
        switch type {
        
        case .call:
            
            for num in contactDetails.phone {
                
                let cleanNum = String(num!.characters.filter { "0123456789".characters.contains($0) })
                guard let url = URL(string: ("tel://" + cleanNum)) else { return }
                let action = UIAlertAction(title: num, style: .default) { _ in
                    UIApplication.shared.open(url)
                }
                alert.addAction(action)
            }
        
        case .text:

            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self
                        
            for num in contactDetails.phone {
                
                let cleanNum = String(num!.characters.filter { "0123456789".characters.contains($0) })
                let action = UIAlertAction(title: num, style: .default) { _ in
                    messageController.recipients = [cleanNum]
                    self.present(messageController, animated: true, completion: nil)
                }
                
                alert.addAction(action)
            }
            
        case .email:
            
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            
            for email in contactDetails.email {
                
                let action = UIAlertAction(title: email, style: .default) { _ in
                    mailController.setToRecipients([email!])
                    self.present(mailController, animated: true, completion: nil)
                }
                
                alert.addAction(action)
            }
            
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
// MARK: - Protocol confirmation methods
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Swift.Error?){
        controller.dismiss(animated: true, completion: nil)
    }
    
}
