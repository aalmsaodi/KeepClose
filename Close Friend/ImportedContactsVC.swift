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
import UserNotifications
import ASValueTrackingSlider
import EPContactsPicker
import CoreData

class ImportedContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UNUserNotificationCenterDelegate, ASValueTrackingSliderDataSource, EPPickerDelegate, NSFetchedResultsControllerDelegate {
    
    var fetchResultsController:NSFetchedResultsController<RefContact>!
    let moc = (UIApplication.shared.delegate as? AppDelegate)?.persistantContainer.viewContext
    let refContactReq = NSFetchRequest<RefContact>(entityName: "RefContact")
    
    var refContacts = [RefContact]()
    var searchFiltered = [SearchFiltered]()
    
    let searchController = UISearchController(searchResultsController: nil)
    let notifCenter = UNUserNotificationCenter.current()
    
    let DEFAULT_PERIOD:TimeInterval = 60 * 60 * 24 * 30 //A notification every month
    var selectedPeriod:TimeInterval = 0
    
    let periodSlider = ASValueTrackingSlider()
    
    @IBOutlet weak var footerMenuBar: NSLayoutConstraint!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var footerStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        projectSetup()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        fetchData()
    }
    
    
    // MARK: - Data Core functions ***************************************************************************
    func setupFetchResultsController() {
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        refContactReq.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: refContactReq, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            print (error.localizedDescription)
        }
    }
    
    func save(name:String, id:String, period:Double) {
        let refContact = RefContact(context: moc!)
        
        refContact.name = name
        refContact.id = id
        refContact.period = period
        
        saveData()
    }
    
    func fetchData() {
        
        do {
            refContacts = try (moc?.fetch(refContactReq))!
            
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
    
    
    // MARK: - Notifcations related methods ******************************************************************
    func notificationPeriodChanged() {
        
        guard let selected_indexPaths = contactsTableView.indexPathsForSelectedRows else {return}
        
        let indecies = selected_indexPaths.map{$0.row}
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            for index in indecies {
                
                removeLocalNotification(id: searchFiltered[index].id)
                
                scheduleLocalNotification(name: searchFiltered[index].name, id: searchFiltered[index].id, period: selectedPeriod)
                
                searchFiltered[index].period = selectedPeriod
                
                let sameContact = refContacts.filter({ contact in
                    return (contact.id!.contains(searchFiltered[index].id))
                })
                
                sameContact[0].period = selectedPeriod
            }
            
            contactsTableView.reloadData()
            
        } else {
            
            for index in indecies {
                
                removeLocalNotification(id: refContacts[index].id!)
                
                scheduleLocalNotification(name: refContacts[index].name!, id: refContacts[index].id!, period: selectedPeriod)
                
                refContacts[index].period = selectedPeriod
            }
        }
    }
    
    
    func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
        
        let value:Int = Int(value)
        var str:String = ""
        
        switch value {
            
        case 1: str = "Twice a week"; selectedPeriod = DEFAULT_PERIOD/15
        case 2: str = "Every week"; selectedPeriod = DEFAULT_PERIOD/4.35
        case 3: str = "Every 2 weeks"; selectedPeriod = DEFAULT_PERIOD/2.14
        case 4: str = "Every month"; selectedPeriod = DEFAULT_PERIOD
        case 5: str = "Every 3 months"; selectedPeriod = DEFAULT_PERIOD*3
        case 6: str = "Every 6 months"; selectedPeriod = DEFAULT_PERIOD*6
        case 7: str = "Every year"; selectedPeriod = DEFAULT_PERIOD*12
        case 8: str = "Every 2 year"; selectedPeriod = DEFAULT_PERIOD*24
            
        default: str = "Every day"; selectedPeriod = DEFAULT_PERIOD/30
        }
        
        return str
    }
    
    func strForPeriod(value:TimeInterval) -> String{
        var str:String = ""
        
        switch value {
            
        case DEFAULT_PERIOD/15: str = "Twice a week"
        case DEFAULT_PERIOD/4.35: str = "Every week"
        case DEFAULT_PERIOD/2.14: str = "Every 2 weeks"
        case DEFAULT_PERIOD: str = "Every month"
        case DEFAULT_PERIOD*3: str = "Every 3 months"
        case DEFAULT_PERIOD*6: str = "Every 6 months"
        case DEFAULT_PERIOD*12: str = "Every year"
        case DEFAULT_PERIOD*24: str = "Every 2 year"
            
        default: str = "Every day"
        }
        
        return str
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let id = response.notification.request.identifier
        ContactNotification.shared.id.append(id)
        
        let tabViewController = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UITabBarController
        let navigationController  = tabViewController.viewControllers?[1] as! UINavigationController
        (navigationController.viewControllers.first as! NotificationsVC).checkAddedNotifications()
        
        IncrementBarButtonBadge()
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler( [.badge, .sound, .init(rawValue: 1)])
        
        let id = notification.request.identifier
        ContactNotification.shared.id.append(id)
        
        let tabViewController = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UITabBarController
        let navigationController  = tabViewController.viewControllers?[1] as! UINavigationController
        (navigationController.viewControllers.first as! NotificationsVC).checkAddedNotifications()
        
        IncrementBarButtonBadge()
    }
    
    
    func IncrementBarButtonBadge() {
        
        let tabController = self.navigationController?.tabBarController
        currentBadgeNum += 1
        
        tabController?.tabBar.items?[tab.notifications].badgeValue = String(currentBadgeNum)
        UIApplication.shared.applicationIconBadgeNumber = currentBadgeNum
        
        UserDefaults.standard.set(currentBadgeNum, forKey: "badgeNum")
    }
    
    
    func localNotificationRequestAccess() {
        
        notifCenter.requestAuthorization(options: [.alert,.sound,.badge]) { (granted,error) in
            
            if granted{
                let connectAction = UNNotificationAction(identifier: "connect", title: "Let's do it", options: [])
                
                let connectCategory = UNNotificationCategory(identifier: "connect.category", actions: [connectAction], intentIdentifiers: [], options: [])
                
                self.notifCenter.setNotificationCategories([connectCategory])
                
            } else {
                
                let alert = UIAlertController(title: "Notification Access", message: "In order to use this application, turn on notification permissions.", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                alert.addAction(alertAction)
                self.present(alert , animated: true, completion: nil)
            }
        }
    }
    
    
    func scheduleLocalNotification(name: String, id: String, period:TimeInterval) {
        let notificationContent = UNMutableNotificationContent()
        
        notificationContent.title = "Let's check up on"
        notificationContent.body = name
        
        notificationContent.categoryIdentifier = "connect"
        
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: period, repeats: false)
        
        let notificationRequest = UNNotificationRequest(identifier: id, content: notificationContent, trigger: notificationTrigger)
        
        notifCenter.add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
    
    func removeLocalNotification(id: String) {
        notifCenter.removeDeliveredNotifications(withIdentifiers: [id])
        notifCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    
    // MARK: - Picking and importing contacts ****************************************************************
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact]) {
        
        for contact in contacts {
            
            if notDuplicated(contacts: refContacts, id: contact.contactId!){
                
                let name = "\(contact.firstName) \(contact.lastName)"
                
                save(name: name, id: contact.contactId!, period: DEFAULT_PERIOD)
                
                scheduleLocalNotification(name: name, id: contact.contactId!, period: DEFAULT_PERIOD)
            }
        }
    }
    
    @IBAction func addContactsTapped(_ sender: UIButton) {
        
        let entityType = CNEntityType.contacts
        let authStatus = CNContactStore.authorizationStatus(for: entityType)
        
        let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:true, subtitleCellType: .phoneNumber)
        let epContactVC = UINavigationController(rootViewController: contactPickerScene)
        
        if authStatus == CNAuthorizationStatus.authorized {
            
            self.present(epContactVC, animated: true, completion: nil)
            
        } else if authStatus == CNAuthorizationStatus.notDetermined {
            
            let contactStore = CNContactStore.init()
            contactStore.requestAccess(for: entityType) { (success, nil) in
                
                if success {
                    self.present(epContactVC, animated: true, completion: nil)
                    
                } else {
                    print("not Authorized")
                }
            }
        }
    }
    
    @IBAction func deleteContacts(_ sender: UIButton) {
        
        if !searchController.isActive {
            
            guard let selected_indexPaths = contactsTableView.indexPathsForSelectedRows else {return}
            
            let indexPaths = selected_indexPaths.sorted().reversed()
            
            for indexPath in indexPaths {
                
                let refContact = fetchResultsController.object(at: indexPath)
                
                removeLocalNotification(id: refContact.id!)
                
                refContact.managedObjectContext?.delete(refContact)
                
                searchFiltered.remove(at: indexPath.row)
            }
        }
    }
    
    func notDuplicated(contacts:[RefContact], id:String) -> Bool {
        
        for contact in contacts {
            if contact.id == id { return false }
        }
        return true
    }
    
    
    // MARK: - TableView and cells ***************************************************************************
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "contactViewCell", for: indexPath) as? ContactViewCell else {
            fatalError("Wrong cell type dequeued")
        }
        
        let avatarInitials: UIImageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        
        
        if searchController.isActive && searchController.searchBar.text != "" {
            cell.contactName.text = searchFiltered[indexPath.row].name
            cell.periodStr.text = strForPeriod(value: searchFiltered[indexPath.row].period)
            
            avatarInitials.setImageForName(string: searchFiltered[indexPath.row].name, backgroundColor: UIColor(red: 0x4F/0xFF, green:0x5D/0xFF, blue: 0x75/0xFF, alpha: 1), circular: false, textAttributes: nil)
            
            cell.contactPic.image = avatarInitials.image
            
        } else {
            
            cell.contactName.text = refContacts[indexPath.row].name
            cell.periodStr.text = strForPeriod(value: refContacts[indexPath.row].period)
            
            avatarInitials.setImageForName(string: refContacts[indexPath.row].name!, backgroundColor: UIColor(red: 0x4F/0xFF, green:0x5D/0xFF, blue: 0x75/0xFF, alpha: 1), circular: false, textAttributes: nil)
            
            cell.contactPic.image = avatarInitials.image
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return searchFiltered.count
        } else {
            return refContacts.count
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
    
    
    // MARK: - Search Bar ************************************************************************************
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
        
    }
    
    func keyboardWasShown(notification: NSNotification) {
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        
        footerMenuBar.constant = keyboardSize!.height - (self.navigationController?.navigationBar.frame.height)!
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        
        footerMenuBar.constant = 0
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        searchFiltered.removeAll()
        
        for refContact in refContacts.filter({ contact in
            return (contact.name?.lowercased().contains(searchText.lowercased()))!
        }) {
            
            searchFiltered.append(SearchFiltered(name: refContact.name!, id: refContact.id!, period: refContact.period))
        }
        
        contactsTableView.reloadData()
        
    }
    
    // MARK: - Project Setup *********************************************************************************
    func projectSetup(){
        
        // Setup Table view
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        contactsTableView.register(UINib(nibName: "ContactViewCell", bundle: nil), forCellReuseIdentifier: "contactViewCell")
        contactsTableView.allowsMultipleSelection = true
        self.automaticallyAdjustsScrollViewInsets = false //To remove top space on top of TableView
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 0x4F/0xFF, green:0x5D/0xFF, blue: 0x75/0xFF, alpha: 1)
        definesPresentationContext = true
        contactsTableView.tableHeaderView = searchController.searchBar
        
        localNotificationRequestAccess()
        notifCenter.delegate = self
        
        setupFetchResultsController()
        
        let tabController = self.navigationController?.tabBarController
        
        // Retrive notification Badge Number
        if let savedBadgeNum = (UserDefaults.standard.value(forKey: "badgeNum") as? Int)  {
            if savedBadgeNum > 0 {
                currentBadgeNum = savedBadgeNum
                tabController?.tabBar.items?[tab.notifications].badgeValue = String(currentBadgeNum)
                UIApplication.shared.applicationIconBadgeNumber = currentBadgeNum
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        tabController?.tabBar.barTintColor = UIColor.white
        
        storyboard?.instantiateViewController(withIdentifier: "notificationsVC")
        
        // Setup Period slider
        periodSlider.dataSource = self
        periodSlider.popUpViewColor = UIColor(red: 0xEF/0xFF, green:0x83/0xFF, blue: 0x54/0xFF, alpha: 1)
        periodSlider.maximumValue = 8
        periodSlider.popUpViewCornerRadius = 12
        periodSlider.addTarget(self, action: #selector(notificationPeriodChanged), for: .touchUpInside)
        footerStackView.insertArrangedSubview(periodSlider, at: 0)
    }
    
}



