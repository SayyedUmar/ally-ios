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
        SwiftEventBus.onMainThread(self, name: "emailLogFile") { result in
            print("emailLogFile")
            let url = FileActions().getFilePath()
            do {
                try self.sendEmail(data: Data(contentsOf: url))
            } catch {print(error.localizedDescription)}
        }
        
        SwiftEventBus.onMainThread(self, name: "onStartMonitoringLocation") { result in
            self.startLocationUpdate()
            guard let result = result, let userInfo = result.userInfo as? [String : Any] else {return}
            self.person = Person (dict: userInfo)
            print("onStartMonitoringLocation", result)
        }
        
        SwiftEventBus.onMainThread(self, name: "onStopMonitoringLocation") { result in
            self.locationManager.stopUpdatingLocation()
            print("onStopMonitoringLocation")
        }
    }
    
    func sendEmail(data:Data?){
        if( MFMailComposeViewController.canSendMail() ) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(["usayyed@xpanxion.com"])
            mailComposer.setSubject("POC Log file")
            mailComposer.setMessageBody("Hey FYI.", isHTML: true)
            
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

class Person {
    let name: String
    let victimId: String
    let deviceId: String
    init (dict: [String: Any]) {
        self.name = dict["name"] as! String
        self.victimId = dict["victimId"] as! String
        self.deviceId = dict["deviceId"] as! String
    }
}
