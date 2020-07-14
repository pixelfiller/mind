//
//  addItemViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 24.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import NaturalLanguage

class addItemViewController: UIViewController, UITextViewDelegate {
    
    let bert = BERT()

    // Reference to NSPersistent Container context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Outlets
    @IBOutlet weak var textInputView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    // Constraints
    @IBOutlet weak var textInputViewBC: NSLayoutConstraint!
    @IBOutlet weak var sendButtonBC: NSLayoutConstraint!
    
    // Actions
    @IBAction func sendButtonTouchDownInside(_ sender: Any) {
        saveNewItem()
        performSegue(withIdentifier: "unwindToHome", sender: self)
    }
    @IBAction func sendButtonTouchDown(_ sender: UIButton) {
        sender.animateButtonDown()
    }
    @IBAction func sendButtonTouchUpOutside(_ sender: UIButton) {
        sender.animateButtonUp()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        textInputView.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardShowNotification:)),
        name: UIResponder.keyboardDidShowNotification,
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardHideNotification:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)
    
        // textInput initial setup
        textInputView.delegate = self
        textInputView.tintColor = UIColor(named: "content")
        
        // sendButton initial setup
        sendButton.layer.cornerRadius = sendButton.frame.size.height / 2.0
        sendButton.clipsToBounds = true
        sendButton.isEnabled = false
        sendButton.isHidden = true
        sendButton.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let itemsViewController = segue.destination as! itemsViewController
        let indexPath = IndexPath(row: 0, section: 0)
        if itemsViewController.items.isEmpty == false {
            itemsViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    
    @objc func saveNewItem() {
        guard let entryText = textInputView?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
        
            var keywords = getKeywords(from: entryText, count: 6)
            keywords = Normalize.getNouns(keywords)

            let newEntry = Item(context: self.context)
            newEntry.id = UUID()
            newEntry.content = entryText
            newEntry.timestamp = Date().current
            newEntry.keywords = keywords
            newEntry.embedding = self.bert.getTextEmbedding(text: entryText)
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }
        }
    }
    
        // Handle keyboard appearence
        @objc private func handle(keyboardShowNotification notification: Notification) {
            if let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                textInputViewBC.constant = keyboardFrame.height + 60
                sendButtonBC.constant = keyboardFrame.height + 18
            }
        }
    
        @objc private func handle(keyboardHideNotification notification: Notification) {
            if let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                sendButtonBC.constant = -keyboardFrame.height - 18
            }
        }
  
    
        // Check if textInput is empty
        func textViewDidChange(_ textView: UITextView) {
            if isTextInputNotEmpty(textView: textInputView) {
                sendButton.show()
            } else {
                sendButton.hide()
            }
        }
        
        
        func isTextInputNotEmpty(textView: UITextView) -> Bool {
            guard let text = textView.text,
                !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                return false
            }
            return true
        }

    
}


// MARK: - UIButton Show/Hide
public extension UIButton {

    func show() {
        self.isHidden = false
        self.isEnabled = true
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.alpha = 1
        }, completion: nil)
    }
    
    func hide() {
        self.isHidden = false
        self.isEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.alpha = 0.0
        }, completion: nil)
    }
}


