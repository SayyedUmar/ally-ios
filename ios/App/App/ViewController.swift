//
//  ViewController.swift
//  LocationServicePOC
//
//  Created by Rahul Mukherjee on 02/06/20.
//  Copyright © 2020 Xpanxion. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var lblCurrentLat: UILabel!
    @IBOutlet weak var lblCurrentLong: UILabel!
    @IBOutlet weak var tableLocationHistory: UITableView!
    @IBOutlet weak var lblBatteryPer: UILabel!
    
    let locationManager = CLLocationManager()
    var pastLocations:NSMutableArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pastLocations = NSMutableArray();
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        self.allPastLocation();
        //self.clearUserDefault();
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(becomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(terminateNotification), name: UIApplication.willTerminateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc func becomeActiveNotification() {
      FileActions().writeToFile("=====becomeActiveNotification=====")
    }
    
    @objc func resignActiveNotification() {
      FileActions().writeToFile("=====resignActiveNotification=====")
    }
    
    @objc func terminateNotification() {
      FileActions().writeToFile("=====terminateNotification=====")
    }
    
    @objc func receiveMemoryWarningNotification() {
      FileActions().writeToFile("=====receiveMemoryWarningNotification=====")
    }

    @IBAction func btnSyncDidTap(_ sender: Any) {
        print("ViewController: Sync Location with server")
        // ToDo : Sync all location to server if needed
    }
    
    @IBAction func btnClearDidTap(_ sender: Any) {
        print("ViewController: clear all historic location data")
        self.clearUserDefault()
        self.pastLocations = NSMutableArray()
        self.tableLocationHistory.reloadData()
    }
    
    private func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
         locationManager.stopUpdatingLocation()
         if (error != nil) {
            print(error.description)
          }
     }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        lblCurrentLong.text = "\(coord.longitude)"
        lblCurrentLat.text = "\(coord.latitude)"
        print("\(coord.longitude) | \(coord.latitude)")
        self.setLocationToUserDefault(lat: "\(coord.longitude)", long: "\(coord.latitude)",battery: String(UIDevice.current.batteryLevel))
    }
    
    func clearUserDefault() {
        UserDefaults.standard.set(nil, forKey: "USER_LOCATION")
    }
    
    func setLocationToUserDefault(lat:String, long:String,battery:String) {
        print("Setting location to user default")
        var locationArray = NSMutableArray()
        if let lastLocationArray = UserDefaults.standard.array(forKey: "USER_LOCATION") {
            locationArray = NSMutableArray(array: lastLocationArray)
        }
        let date = Date()
        let locationString = "lat: \(lat) | long: \(long) at \(date) | battery is \(battery)"
        self.writeToFile(writeData: locationString)
         // ToDo Send new locationString to server using API Call
        locationArray.add(locationString)
        self.pastLocations = NSMutableArray(array: locationArray)
        self.tableLocationHistory.reloadData()
        UserDefaults.standard.set(locationArray, forKey: "USER_LOCATION")
    }
    
    func allPastLocation() {
        if let lastLocationArray = UserDefaults.standard.array(forKey: "USER_LOCATION") {
            print("All Past Location")
            self.pastLocations = NSMutableArray(array: lastLocationArray)
            self.tableLocationHistory.reloadData()
            for loc in lastLocationArray {
                print(loc)
            }
        }
    }
    
    
}


extension ViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let pastLocations = self.pastLocations {
            return pastLocations.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PAST_LOCATION_CELL", for: indexPath)
        if let pastLocations = self.pastLocations, let lblText = cell.viewWithTag(1) as? UILabel {
            lblText.text = pastLocations[indexPath.row] as? String
        }
        return cell;
    }
}

extension ViewController {
    func getFilePath() -> URL {
        let fileName = "locations"
        let documentDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDir.appendingPathComponent(fileName).appendingPathExtension("txt")

        return fileURL
    }
    
    func writeToFile(writeData:String) {
        let filePath :URL = self.getFilePath()
        do {
            // write to file
            print("\(filePath)")
            var locationsInFile = ""
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath.path){
                locationsInFile = try String(contentsOf: filePath)
            }
            let data = locationsInFile + writeData
            try data.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
            
            
            //try writeData.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Fail to write at URL : \(error.localizedDescription)")
        }
    }
    
    func readFromFile() {
        let filePath :URL = self.getFilePath()
        var locationsInFile = ""
        do {
            // Read from file
            try locationsInFile = String(contentsOf: filePath)
        } catch let error as NSError {
             print("Fail to read at URL : \(error.localizedDescription)")
        }
        print("Content of File : \(locationsInFile)")
    }
}



