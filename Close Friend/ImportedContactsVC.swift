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
import MessageUI


class ImportedContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, CNContactPickerDelegate, UISearchResultsUpdating {

    let contactStore = CNContactStore()
    
    var filteredContacts:[(String,String)] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var contactsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        contactsTableView.register(UINib(nibName: "ContactViewCell", bundle: nil), forCellReuseIdentifier: "contactViewCell")
        
        contactsTableView.allowsMultipleSelection = true
        self.automaticallyAdjustsScrollViewInsets = false //To remove top space on top of TableView
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        contactsTableView.tableHeaderView = searchController.searchBar
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
    
        guard let selected_indexPaths = contactsTableView.indexPathsForSelectedRows else {return}
        
        let indecies = selected_indexPaths.map{$0.row}.sorted(by: {$0 > $1})

        for indx in indecies {
            Contact.importedContactsIDs.remove(at: indx)
        }

        let contactDect:[String: String] = ["id": Contact.importedContactsIDs[0].1]
        
        //temp code
        NotificationCenter.default.post(name: .contactNotification, object: nil, userInfo: contactDect)
        
        
        contactsTableView.deleteRows(at: selected_indexPaths, with: UITableViewRowAnimation.automatic)
    }
    
    
// MARK: - Picking and importing contacts
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
                
        for contact in contacts {
            
            if !tupleContains(arr: Contact.importedContactsIDs, str: contact.identifier){ //to avoid duplicates
                
                let name = CNContactFormatter.string(from: contact, style: .fullName)
                
                Contact.importedContactsIDs.append((name!, contact.identifier))
                filteredContacts.append((name!, contact.identifier))
            }
        }
        
        Contact.importedContactsIDs.sort(by: { $0.0 < $1.0 })
        
        contactsTableView.reloadData()
    }
    
    func openContacts(){
        
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.delegate = self
        
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        
        picker.dismiss(animated: true)
    }
    
    func tupleContains(arr:[(String, String)], str:String) -> Bool {

        for (_, value) in arr {
            if value == str { return true }
        }
        return false
    }
    

// MARK: - TableView and cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactViewCell", for: indexPath) as! ContactViewCell
        
        if searchController.isActive && searchController.searchBar.text != "" {
            cell.contactName.text = filteredContacts[indexPath.row].0
            cell.contactBtn.tag = indexPath.row
            cell.contactBtn.addTarget(self, action: #selector(contactOptionsAction), for: .touchUpInside)
        
        } else {
            cell.contactName.text = Contact.importedContactsIDs[indexPath.row].0
            cell.contactBtn.tag = indexPath.row
            cell.contactBtn.addTarget(self, action: #selector(contactOptionsAction), for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredContacts.count
        }
        return Contact.importedContactsIDs.count
    }
    
    @IBAction func contactOptionsAction(sender: UIButton) {
        performSegue(withIdentifier: "goToContactDetails", sender: sender)
    }

    
// MARK: - Search Bar
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredContacts = Contact.importedContactsIDs.filter { contact in
            return contact.0.lowercased().contains(searchText.lowercased())
        }
        
        contactsTableView.reloadData()
    }
    
    
// MARK: - Prepare for seguae
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        
        if segue.identifier == "goToContactDetails" {

//            let upcomingContactDetailsVC = segue.destination as! ContactDetailsVC
//            let index = (sender as! UIButton).tag
//            
//            upcomingContactDetailsVC.contactDetails = importedContacts[index]

        }
    }
}

