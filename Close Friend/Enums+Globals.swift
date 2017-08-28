//
//  Enums+Globals.swift
//  Close Friend
//
//  Created by user on 8/17/17.
//  Copyright © 2017 YSH. All rights reserved.
//

import Foundation

struct tab {
    static let contacts = 0
    static let notifications = 1
    static let settings = 2
}

enum typeOfAction {
    case call
    case text
    case email
    case social
}

var currentBadgeNum:Int = 0

var contactNotifications = [ContactNotification]()
