//
//  Notifications.swift
//  Close Friend
//
//  Created by user on 8/3/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import UIKit
import Contacts
import MessageUI
import UserNotifications
import InitialsImageView
import CoreData

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, NSFetchedResultsControllerDelegate {
    
    var fetchResultsController:NSFetchedResultsController<Contact>!
    let moc = (UIApplication.shared.delegate as? AppDelegate)?.persistantContainer.viewContext
    let ContactReq = NSFetchRequest<Contact>(entityName: "Contact")
    
    var contacts:[Contact] = []
    
    var isCellEditing = false
    
    @IBOutlet weak var contactsTableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkMissedNotifications), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        contactsTableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: "notificationCell")
        
        contactsTableView.allowsSelection = false
        self.automaticallyAdjustsScrollViewInsets = false //To remove top space on top of TableView
        
        setupFetchResultsController()
        
        fetchData()
        
    }
    

// MARK: - Data Core functions
    func save(name:String, phones:[String], emails:[String], jobTitle:String, image:UIImage) {
        let contact = Contact(context: moc!)
        
        contact.name = name
        contact.jobTitle = jobTitle
        contact.image = UIImagePNGRepresentation(image) as NSData?
        
        for num in phones {
            let phone = Phone(context: moc!)
            phone.num = num
            
            contact.addToPhone(phone)
        }
        
        for address in emails {
            let email = Email(context: moc!)
            email.address = address

            contact.addToEmail(email)
        }
        
        saveData()
    }
    

    func setupFetchResultsController() {
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        ContactReq.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: ContactReq, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            print (error.localizedDescription)
        }
    }
    

    func fetchData() {
        do {
            contacts = try (moc?.fetch(ContactReq))!
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveData() {
        do {
            try moc?.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
// MARK: - Notifications functions
    func checkAddedNotifications() {
        
        for (index,id) in ContactNotification.shared.id.enumerated().reversed() {
            self.getContactFromID(contactID: id)
            ContactNotification.shared.id.remove(at: index)
        }
        
    }
    
    func checkMissedNotifications() {

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getDeliveredNotifications() {notifications in
            
            var incrementBadgeBy = 0
            
            for notification in notifications {
                let contactID = notification.request.identifier
                self.getContactFromID(contactID: contactID)
                
                incrementBadgeBy += 1
                
                notificationCenter.removeDeliveredNotifications(withIdentifiers: [contactID])
            }
            
            if incrementBadgeBy > 0 {
                DispatchQueue.main.async() {
                    self.changeBadgeCount(by: incrementBadgeBy)
                }
            }
        }
    }
    
    func changeBadgeCount(by:Int) {
        
        let tabController = self.navigationController?.tabBarController
        currentBadgeNum += by
        
        UIApplication.shared.applicationIconBadgeNumber = currentBadgeNum
        
        if currentBadgeNum > 0 {
            tabController?.tabBar.items?[tab.notifications].badgeValue = String(currentBadgeNum)
        } else {
            tabController?.tabBar.items?[tab.notifications].badgeValue = nil
        }
        
        UserDefaults.standard.set(currentBadgeNum, forKey: "badgeNum")

    }
    
    func getContactFromID(contactID: String) {
        
        var phones:[String] = []
        var emails:[String] = []
        
        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactID])
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactJobTitleKey]
        
        var contacts = [CNContact]()
        
        do {
            contacts = try CNContactStore().unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
            
        }catch {
            print("Unable to fetch contact")
        }
        
        let name = contacts[0].givenName + " " + contacts[0].familyName
        
        for number in contacts[0].phoneNumbers {
            phones.append(number.value.stringValue)
        }
        
        for email in contacts[0].emailAddresses {
            emails.append(email.value as String)
        }
        
        
        let avatarInitials: UIImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        avatarInitials.setImageForName(string: name, backgroundColor: nil, circular: false, textAttributes: nil)
        
//        let avatarInitialsData = UIImagePNGRepresentation(avatarInitials.image!) as Data?
        
        //UIImage(data: (contacts[0].imageData ?? avatarInitialsData)!)
        
        let jobTitle = contacts[0].jobTitle
        
        save(name: name, phones: phones, emails: emails, jobTitle: jobTitle, image: avatarInitials.image!)

    }
    
    
    // MARK: - TableView and cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath) as? NotificationCell else {
            fatalError("Wrong cell type dequeued")
        }
        
        cell.callBtn.tag = indexPath.row
        cell.textBtn.tag = indexPath.row
        cell.emailBtn.tag = indexPath.row
        
        cell.name.text = contacts[indexPath.row].name
        cell.pic.image = UIImage(data: contacts[indexPath.row].image! as Data)
        cell.job.text = contacts[indexPath.row].jobTitle
        cell.callBtn.addTarget(self, action: #selector(callTapped(sender:)), for: .touchUpInside)
        cell.textBtn.addTarget(self, action: #selector(textTapped(sender:)), for: .touchUpInside)
        cell.emailBtn.addTarget(self, action: #selector(emailTapped(sender:)), for: .touchUpInside)
        
        if contacts[indexPath.row].phone?.count == 0 {
            cell.callBtn.isHidden = true; cell.textBtn.isHidden = true
        }
        if contacts[indexPath.row].email?.count == 0 {
            cell.emailBtn.isHidden = true
        }
        if contacts[indexPath.row].jobTitle == "" {
            cell.job.isHidden = true
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .delete {
            contacts.remove(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete){
            
            let contact = fetchResultsController.object(at: indexPath)
            contact.managedObjectContext?.delete(contact)
            
            if contacts.count == 0 {
                isCellEditing = false
                contactsTableView.isEditing = isCellEditing
            }
            
            changeBadgeCount(by: -1)
        }
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contactsTableView.beginUpdates()
        
       fetchData()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contactsTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                contactsTableView.insertRows(at: [indexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                contactsTableView.deleteRows(at: [indexPath], with: .fade)
                saveData()
            }
        case .update:
            if let indexPath = indexPath {
                contactsTableView.reloadRows(at: [indexPath], with: .fade)
            }
        case .move:
            if let indexPath = indexPath {
                contactsTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                contactsTableView.insertRows(at: [newIndexPath], with: .fade)
            }
        }
    }
    
    
    @IBAction func tableRefreshBtn(_ sender: Any){
        checkAddedNotifications()
        contactsTableView.reloadData()
    }
    
    func callTapped(sender:UIButton) {
        
        if contacts[sender.tag].phone?.count == 1 {
            let num = ((contacts[sender.tag].phone?.allObjects as? [Phone])?.first?.num)!
            let cleanNum = String(num.characters.filter { "0123456789".characters.contains($0)})

            guard let urlNum = URL(string: ("tel://\(cleanNum)")) else { return }
            UIApplication.shared.open(urlNum)
            
        } else if (contacts[sender.tag].phone?.count)! > 1 {
            
            CustomActionOptions(type: .call, index: sender.tag)
        }
    }
    
    func textTapped(sender:UIButton) {
        
        if (MFMessageComposeViewController.canSendText()) {
            
            if contacts[sender.tag].phone?.count == 1 {
                let num = ((contacts[sender.tag].phone?.allObjects as? [Phone])?.first?.num)!
                let cleanNum = String(num.characters.filter { "0123456789".characters.contains($0)})

                let messageController = MFMessageComposeViewController()
                messageController.messageComposeDelegate = self
                
                messageController.recipients = [cleanNum]
                
                self.present(messageController, animated: true, completion: nil)
                
            } else if (contacts[sender.tag].phone?.count)! > 1 {
                
                CustomActionOptions(type: .text, index: sender.tag)
            }
        }
    }
    
    
    func emailTapped(sender:UIButton) {
        if (MFMailComposeViewController.canSendMail()) {
            
            let email = contacts[sender.tag].email
                        
            if email?.count == 1 {
                
                let mailController = MFMailComposeViewController()
                mailController.mailComposeDelegate = self
                
                let email = (contacts[sender.tag].email?.allObjects as? [Email])?.first?.address
                
                mailController.setToRecipients([email!])
                self.present(mailController, animated: true, completion: nil)
                
            } else if (email?.count)! > 1 {
                
                CustomActionOptions(type: .email, index: sender.tag)
            }
            
        } else {
            
            let alert = UIAlertController(title: "Make sure that you have an Email account setup correctly on this device", message: "", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    
// MARK: - Handiling multiple contact actions
    func CustomActionOptions(type:typeOfAction, index:Int){

        let alert = UIAlertController(title: "Please choose one", message: "", preferredStyle: .alert)
        var action:UIAlertAction? = nil
        
        switch type {
            
        case .call:
            
            for phone in (contacts[index].phone?.allObjects as? [Phone])! {
                
                let cleanNum = String(phone.num!.characters.filter { "0123456789".characters.contains($0) })
                guard let url = URL(string: ("tel://" + cleanNum)) else { return }
                action = UIAlertAction(title: phone.num, style: .default) { _ in
                    UIApplication.shared.open(url)
                }
                alert.addAction(action!)
            }
            
        case .text:
            
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self
            
            for phone in (contacts[index].phone?.allObjects as? [Phone])!  {
                
                let cleanNum = String(phone.num!.characters.filter { "0123456789".characters.contains($0) })
                action = UIAlertAction(title: phone.num, style: .default) { _ in
                    messageController.recipients = [cleanNum]
                    self.present(messageController, animated: true, completion: nil)
                }
                
                alert.addAction(action!)
            }
            
        case .email:
            
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            
            for email in (contacts[index].email?.allObjects as? [Email])! {
                
                action = UIAlertAction(title: email.address, style: .default) { _ in
                    mailController.setToRecipients([email.address!])
                    self.present(mailController, animated: true, completion: nil)
                }
                
                alert.addAction(action!)
            }
            
        default:
            break
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(cancelAction)
        
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

