//
//  operation.swift
//  App
//
//  Created by Umar on 27/07/20.
//

import Foundation
import MessageUI
import SwiftEventBus
import Capacitor

class RefreshAppContentsOperation {
    
    
}

extension AppDelegate {
    
    func subscribeBusEvents () {
        SwiftEventBus.onMainThread(self, name: "emailLogFile") { result in
            print("emailLogFile")
            let url = FileActions().getFilePath()
            let url1 = FileActions1().getFilePath()
            let url2 = FileActions2().getFilePath()
            do {
                try self.sendEmail(data: Data(contentsOf: url), data1: Data(contentsOf: url1), data2: Data(contentsOf: url2))
            } catch {print(error.localizedDescription)}
        }
        
        SwiftEventBus.onMainThread(self, name: "onStartMonitoringLocation") { result in
            self.startLocationUpdate()
//            self.callDummyApi(location: nil)
            guard let result = result, let userInfo = result.userInfo as? [String : Any] else {return}
            self.person = Person (dict: userInfo)
            print("onStartMonitoringLocation", result)
        }
        
        SwiftEventBus.onMainThread(self, name: "onStopMonitoringLocation") { result in
            self.locationManager.stopUpdatingLocation()
            print("onStopMonitoringLocation")
        }
    }
    
    func sendDataToIonic (info:[String: Any]) {
        NotificationCenter.default.post(
                        name: NSNotification.Name.init("onLocationCapture"),
                        object: self,
                        userInfo: info)
    }
    
//    func sendDataToIonic (dic:[String: Any]) {
//        let capVC = self.window?.rootViewController as? CAPPlugin
//        capVC?.bridge.triggerDocumentJSEvent(eventName: "onLocationCapture", data: dic)
//    }
    
    func sendEmail(data:Data?, data1:Data?, data2:Data?){
        if( MFMailComposeViewController.canSendMail() ) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(["usayyed@xpanxion.com","tmohod@xpanxion.com"])
            mailComposer.setCcRecipients(["apatil1@xpanxion.com"])
            mailComposer.setSubject("POC Log file")
            mailComposer.setMessageBody("Hey FYI.", isHTML: true)
            
            if let fileData = data {
                mailComposer.addAttachmentData(fileData, mimeType: "application/pdf", fileName: "fileLogs.txt")
            }
            if let fileData = data1 {
                mailComposer.addAttachmentData(fileData, mimeType: "application/pdf", fileName: "locationLogs.txt")
            }
            
            if let fileData = data2 {
                mailComposer.addAttachmentData(fileData, mimeType: "application/pdf", fileName: "apilogs.txt")
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
