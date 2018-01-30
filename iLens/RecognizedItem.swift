//
//  RecognizedItem.swift
//  iLens
//
//  Created by Ostap Horbach on 1/30/18.
//  Copyright © 2018 Ostap Horbach. All rights reserved.
//

import UIKit

protocol RecognizedItemAction {
    var title: String { get }
    func performAction(_ item: RecognizedItem)
}

struct CopyAction: RecognizedItemAction {
    var title: String = "Copy"
    func performAction(_ item: RecognizedItem) {
        UIPasteboard.general.string = item.text
    }
}

struct OpenURLAction: RecognizedItemAction {
    var title: String = "Open URL"
    func performAction(_ item: RecognizedItem) {
        if let item = item as? RecognizedURLItem {
            UIApplication.shared.open(item.URL, options: [:], completionHandler: nil)
        }
    }
}

struct WriteEmailAction: RecognizedItemAction {
    var title: String = "Write email"
    func performAction(_ item: RecognizedItem) {
        if let item = item as? RecognizedEmailItem {
            UIApplication.shared.open(item.emailURL, options: [:], completionHandler: nil)
        }
    }
}

struct CallAction: RecognizedItemAction {
    var title: String = "Call"
    func performAction(_ item: RecognizedItem) {
        if let item = item as? RecognizedPhoteNumberItem {
            UIApplication.shared.open(item.phoneURL, options: [:], completionHandler: nil)
        }
    }
}

protocol RecognizedItem {
    var text: String { get }
    var supportedActions: [RecognizedItemAction] { get }
}

struct RecognizedTextItem: RecognizedItem {
    var text: String
    var supportedActions: [RecognizedItemAction] {
        return [CopyAction()]
    }
}

struct RecognizedEmailItem: RecognizedItem {
    var text: String
    var emailURL: URL
    var supportedActions: [RecognizedItemAction] {
        return [CopyAction(), WriteEmailAction()]
    }
}

struct RecognizedURLItem: RecognizedItem {
    var text: String
    var URL: URL
    var supportedActions: [RecognizedItemAction] {
        return [CopyAction(), OpenURLAction()]
    }
}

struct RecognizedPhoteNumberItem: RecognizedItem {
    var text: String
    var phoneURL: URL
    var supportedActions: [RecognizedItemAction] {
        return [CopyAction(), CallAction()]
    }
}
