//
//  ThoughtExtension.swift
//  Mind
//
//  Created by Anton Evstigneev on 19.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import CoreData
import UIKit


// MARK: - Data
var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext


extension Thought {
    
    enum ThoughtState: String {
        case favorited = "favorited"
        case locked = "locked"
        case archived = "archived"
    }
    
    func toggleState(_ state: ThoughtState) {
        
        var options: [ThoughtState: Bool] = [
            .favorited: false,
            .locked: false,
            .archived: false,
        ]
    
        options[state]!.toggle()
        
        switch state {
            case .favorited:
                self.favorited.toggle()
            case .locked:
                self.locked.toggle()
            case .archived:
                self.archived.toggle()
        }
        
        // Update thought data
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if MindCloud.isUserAuthorized {
            MindCloud.updateThought(id: self.id!, upd: [state.rawValue: options[state]!]) {
                (responseData, success) in
                if (success) {
                    print("✅ 🔐 Authorized thought update success.")
                }
            }
        }
    }
    
    func delete() {
        context.delete(self)
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if MindCloud.isUserAuthorized {
            MindCloud.deleteThought(id: self.id!) { (responseData, success) in
                if (success) {
                    print("✅ 🔐 Authorized thought deletion success.")
                }
            }
        }
    }
}


