//
//  ViewController.swift
//  Close Friend
//
//  Created by user on 7/28/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ImportedContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, CNContactPickerDelegate {

    var contactStore = CNContactStore()
    var importedContactsData:[Contact] = []

    
    @IBOutlet weak var contactsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        contactsTableView.register(UINib(nibName: "ContactViewCell", bundle: nil), forCellReuseIdentifier: "contactViewCell")
        
        contactsTableView.allowsMultipleSelection = true
        self.automaticallyAdjustsScrollViewInsets = false
        
    }
  
    @IBAction func addContactsTapped(_ sender: UIButton) {
        
        let entityType = CNEntityType.contacts
        let authStatus = CNContactStore.authorizationStatus(for: entityType)
        
        if authStatus == CNAuthorizationStatus.authorized {
          
            self.openContacts()
            
        } else if authStatus == CNAuthorizationStatus.notDetermined {
            
            let contactStore = CNContactStore.init()
            contactStore.requestAccess(for: entityType, completionHandler: { (success, nil) in
                
                if success {
                    self.openContacts()
                    
                } else {
                    print("not Authorized")
                }
            })
        }
    }
    
    @IBAction func deleteContacts(_ sender: UIButton) {
    
        let selected_indexPaths = contactsTableView.indexPathsForSelectedRows
        
        if let indices = selected_indexPaths?.indices {

            for index in indices.reversed() {
                Contact.importedContactsIDs.remove(at: index+1)
                importedContactsData.remove(at: index+1)
            }
            
            importedContactsData.sort(by: {$0.name < $1.name})
            Contact.importedContactsIDs.sort(by: { $0.0 < $1.0 })

            contactsTableView.deleteRows(at: selected_indexPaths!, with: UITableViewRowAnimation.automatic)
        }
        
    }
    
    
    func openContacts(){
        
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.delegate = self
        
        self.present(contactPicker, animated: true, completion: nil)
        
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        
        picker.dismiss(animated: true)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        
        let defaultImage = UIImagePNGRepresentation(UIImage(named: "1")!)!
        var numbers, emails: [String]
        
        for contact in contacts {
            
            if !contains(arr: Contact.importedContactsIDs, str: contact.identifier){
                let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                
                for number in contact.phoneNumbers {
                    numbers.append(number.value.stringValue)
                }
                
                for email in contact.emailAddresses {
                    emails.append(email.value as String)
                }
                
                let pic = UIImage(data: contact.imageData ?? defaultImage)
                
                Contact.importedContactsIDs.append((fullName!,contact.identifier))
                importedContactsData.append(Contact(name: fullName!, phone: numbers, email: emails, image: pic))
            }
            
        }
        
        importedContactsData.sort(by: {$0.name < $1.name})
        Contact.importedContactsIDs.sort(by: { $0.0 < $1.0 })
        contactsTableView.reloadData()
        
    }
    
    func contains(arr:[(String, String)], str:String) -> Bool {

        for (_, value) in arr {
            if value == str { return true }
        }
        return false
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactViewCell", for: indexPath) as! ContactViewCell
        
        cell.contactNum.text = importedContactsData[indexPath.row].phone
        cell.contactName.text = importedContactsData[indexPath.row].name
        cell.contactPic.image = importedContactsData[indexPath.row].image
        
        cell.contactBtn.tag = indexPath.row
        cell.contactBtn.addTarget(self, action: #selector(contactOptionsAction), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return importedContactsData.count
    }
    
    @IBAction func contactOptionsAction(sender: UIButton) {
        performSegue(withIdentifier: "goToContactDetails", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        
        if segue.identifier == "goToContactDetails" {

            let upcomingContactDetailsVC = segue.destination as! ContactDetailsVC
            let index = (sender as! UIButton).tag
            
            upcomingContactDetailsVC.titleString = importedContactsData[index].phone!
        }
    }
}

