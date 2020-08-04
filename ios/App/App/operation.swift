//
//  operation.swift
//  App
//
//  Created by Umar on 27/07/20.
//

import Foundation
import MessageUI
import SwiftEventBus

class RefreshAppContentsOperation {
    
    
}

extension AppDelegate {
    
    func subscribeBusEvents () {
        SwiftEventBus.onMainThread(self, name: "CAPPluginCall_umar") { result in
            // UI thread
            //print("CAPPluginCall_umar")
            let url = FileActions().getFilePath()
            
            do {
                try self.sendEmail(data: Data(contentsOf: url))
            } catch {print(error.localizedDescription)}
            
        }
    }
    
    func sendEmail(data:Data?){
        if( MFMailComposeViewController.canSendMail() ) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(["john@stackoverflow.com", "mrmins@mydomain.com", "anotheremail@email.com"])
            mailComposer.setSubject("Cotización")
            mailComposer.setMessageBody("My body message", isHTML: true)
            
            if let fileData = data {
                mailComposer.addAttachmentData(fileData, mimeType: "application/pdf", fileName: "MyFileName.txt")
            }
            
            if let window = self.window, let rootVC = window.rootViewController {
                rootVC.present(mailComposer, animated: true, completion: nil)
            }
            
            return
        }
        print("Email is not configured")
        
    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let window = self.window, let rootVC = window.rootViewController {
            rootVC.dismiss(animated: true, completion: nil)
        }
        
    }
}
