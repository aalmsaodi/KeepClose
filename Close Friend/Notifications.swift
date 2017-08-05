//
//  Notifications.swift
//  Close Friend
//
//  Created by user on 8/3/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import MessageUI


extension Notification.Name {
    static let contactNotification = Notification.Name("contactNotification")
}

class Notifications: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var contactStore = CNContactStore()
    var contactsToBeContacted:[Contact] = []
    
    @IBOutlet weak var contactsTableView: UITableView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
         NotificationCenter.default.addObserver(self, selector: #selector(contactsToBeContactRecieved(notification:)), name: .contactNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        contactsTableView.register(UINib(nibName: "ContactViewCell", bundle: nil), forCellReuseIdentifier: "contactViewCell")
        
        contactsTableView.allowsMultipleSelection = true
        self.automaticallyAdjustsScrollViewInsets = false //To remove top space on top of TableView

    }
    

    func contactsToBeContactRecieved(notification: NSNotification) {
        
        let contactID = notification.userInfo?["id"] as? String
        
        contactsToBeContacted.append(getContactFromID(contactID: contactID!))
        
//        contactsTableView.reloadData()
    }

    func getContactFromID(contactID: String) -> Contact {
        
        let newContact = Contact()

        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactID])
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactJobTitleKey]
        
        var contacts = [CNContact]()
        
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
        
        }catch {
            print("Unable to fetch contact")
        }
        
        newContact.name = contacts[0].givenName + " " + contacts[0].familyName
        
        for number in contacts[0].phoneNumbers {
            newContact.phone.append(number.value.stringValue)
        }
        
        for email in contacts[0].emailAddresses {
            newContact.email.append(email.value as String)
        }
        
        let defaultImage = UIImagePNGRepresentation(UIImage(named: "1")!) as Data?
        newContact.image = UIImage(data: (contacts[0].imageData ?? defaultImage)!)
        
        newContact.jobTitle = contacts[0].jobTitle 
        
        return newContact
    }
    
    // MARK: - TableView and cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactViewCell", for: indexPath) as! ContactViewCell
        
            cell.contactName.text = contactsToBeContacted[indexPath.row].name
            cell.contactPic.image = contactsToBeContacted[indexPath.row].image
            cell.contactBtn.tag = indexPath.row
            cell.contactBtn.addTarget(self, action: #selector(contactOptionsAction), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contactsToBeContacted.count
    }
    
    @IBAction func contactOptionsAction(sender: UIButton) {
        performSegue(withIdentifier: "goToContactDetails", sender: sender)
    }
    
    
    // MARK: - Prepare for seguae
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        
        if segue.identifier == "goToContactDetails" {
            
            let upcomingContactDetailsVC = segue.destination as! ContactDetailsVC
            let index = (sender as! UIButton).tag
            
            upcomingContactDetailsVC.contactDetails = contactsToBeContacted[index]
            
        }
    }
}

