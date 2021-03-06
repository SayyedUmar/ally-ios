//
//  MLocationManager.swift
//  App
//
//  Created by Umar on 30/07/20.
//

import Foundation
import CoreLocation
import UIKit
//import Alamofire
import SwiftyJSON

class MLocationManager: NSObject {
    

    
}


class Geotification {
    var identifier: String
    let cord: CLLocationCoordinate2D
    init (identifier: String, cord: CLLocationCoordinate2D) {
        self.identifier = identifier
        self.cord = cord
    }
}

extension AppDelegate {
    
    func getMinutesDifferenceFromTwoDates(start: Date, end: Date) -> Int {
        let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)
        let hours = diff / 3600
        let minutes = (diff - hours * 3600) / 60
        return minutes
    }
    
    func requestPermission () {
        
        //self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
        //locationManager.startUpdatingLocation()
        //self.locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdate(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
    }
    
    func callDummyApi (location: CLLocation?) {
//        let coord = location.coordinate
//        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
        let url = URL(string: "http://localhost:8004/testAPI")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let d = data, error == nil
                else {
                    print("error received", data!.toString)
                    return }
//            let dic = d.toJSON()
//            print("response received",data?.toJSON())
            //FileActions().writeToFile("\(dic?["title"]!) Lat -\(coord.latitude) | Long - \(coord.longitude)")

        }.resume()
        
//        Alamofire.request("http://localhost:8004/testAPI",method: .get, parameters: [:], headers: [:])
//            //         .validate(contentType: [contentType])
//            .responseJSON { (response) in
//                switch response.result {
//
//                case .success:
//                    print("success")
//                    break;
//
//                case .failure(let error):
//                    print("failure")
//                    break;
//                }
//                if let value = response.data {
//                    let json = JSON(value)
//                    print("Response: ", json)
//                    //FileActions2().writeToFile(value.toString)
//                } else {
//                }
//        }
    }
    func callServerAPI (location: CLLocation) {
        let c = location.coordinate
        let body = getPostData(location: location).toData
        print("body- \(getPostData(location: location))")
        
        #if targetEnvironment(simulator)
        print("device is simulator")
        return;
        #endif
        print("device is real")
        
        FileActions1().writeToFile("location_status=\(getLocationSerStatus()), internet=\(Reachability.isConnectedToNetwork()) lat:\(c.latitude), lng: \(c.longitude), accuracy:\(location.horizontalAccuracy)")
        
        FileActions2().writeToFile("location_status=\(getLocationSerStatus()), internet=\(Reachability.isConnectedToNetwork()) request=\(body!.toString)")
        
        let url = URL(string: "https://allymobileapigateway.scramstage.com/api/v1/NativeMobile/Location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        print("location- ", c.latitude, c.longitude)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
//        Alamofire.request("http://localhost:8004/testAPI",method: .get, parameters: [:], headers: [:])
//            //         .validate(contentType: [contentType])
//            .responseJSON { (response) in
//
////                switch response.result {
////                case .success:
////                    break;
////                case .failure(let error):
////                    break;
////                }
//                guard let statusCode = response.response?.statusCode else {return}
//                if (statusCode == 200) {
//                    print("API Call Successful", statusCode)
//                    FileActions1().writeToFile("API Call Successful:statusCode:\(statusCode)")
//                    FileActions2().writeToFile("API Call Successful:statusCode:\(statusCode)")
//
//                } else {
//                    print("API Call Failed", statusCode)
//                    if let value = response.data {
//                        //let json = JSON(value)
//                        FileActions1().writeToFile("API Call Failed: statusCode:\(statusCode), error:\(value.toString)")
//                        FileActions2().writeToFile("API Call Failed: statusCode:\(statusCode), error:\(value.toString)")
//                    } else {
//                    }
//                }
//
//        }
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let d = data, error == nil
                else {
                    if let res = response as? HTTPURLResponse, let data = data {
                        FileActions1().writeToFile("API Call Failed: statusCode:\(res.statusCode), error:\(data.toString)")
                        FileActions2().writeToFile("API Call Failed: statusCode:\(res.statusCode), error:\(data.toString)")
                        self.sendDataToIonic(info: ["lat":c.latitude, "lng": c.longitude,
                                                    "statusCode": res.statusCode,
                                                    "response": data.toString,
                                                    "request": body!.toString
                        ])
                    }

                    return
            }
            FileActions1().writeToFile("API Call Successful:statusCode:\(httpURLResponse.statusCode)")
            FileActions2().writeToFile("API Call Successful:statusCode:\(httpURLResponse.statusCode)")
            self.sendDataToIonic(info: ["lat":c.latitude, "lng": c.longitude, "statusCode": httpURLResponse.statusCode])
        }.resume()
    }
    
    func getPostData (location: CLLocation) -> [[String: Any]] {
        return [[
            "victimId": self.person.victimId,
            "deviceImei": self.person.deviceId,
//            "victimId": "84C515A8-A00D-4E06-81B4-48592351C096",
//            "deviceImei": "9233c89d05d89799",
            "timestamp": Date().toUTCString("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "altitudeAccuracy": location.verticalAccuracy,
            "direction": direction == nil ? 0 : direction.magneticHeading,
            "speed": location.speed,
            "satellite": 0,
            "csq": 0,
            "isMoving": false, //calculated based on activityType
            "fix": 0, //zero
            "address": "address",
            "locationMode": "A",
            "eventType": "Location",
            "cacheTimeStamp": location.timestamp.toUTCString("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            "activityType": "activityType",
            "activityConfidence": -1,
            "batteryLevel": Double(round(1000*UIDevice.current.batteryLevel*100)/1000),
            "isBatteryCharging": UIDevice.current.batteryState == .charging ? true : false,
        ]]
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        direction = newHeading
        //print("direction = magneticHeading:\(direction.magneticHeading), trueHeading:\(direction.trueHeading))")
        //scheduleLocalNotification(title: "Ally", body: "New Directon: \(direction.trueHeading):\(direction.magneticHeading)", info: nil)
    }
    
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == geotification.identifier else { continue }
            print("stopRegionMonitoring: \(circularRegion.center.latitude) - \(circularRegion.center.longitude)")
            FileActions().writeToFile("stopRegionMonitoring: \(circularRegion.center.latitude) - \(circularRegion.center.longitude)")
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func monitorRegionAtLocation (center: CLLocationCoordinate2D, identifier: String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("startRegionMonitoring: \(center.latitude) - \(center.longitude)")
            FileActions().writeToFile("startRegionMonitoring: \(center.latitude) - \(center.longitude)")
            let maxDistance = locationManager.maximumRegionMonitoringDistance
            let region = CLCircularRegion(center: center,
                                          radius: 100/*in meters*/, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
    }
    
    func userExitedRegion (region: CLCircularRegion) {
        FileActions().writeToFile("region exited: \(region.center.latitude):\(region.center.longitude)")
        stopMonitoring(geotification: Geotification(identifier: region.identifier, cord: region.center))
        self.geotification = nil
        self.startLocationUpdate()
    }
    
    //MARK: Location service detection
    func getLocationSerStatus()-> String {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    return "NotAuthorised"
                case .authorizedWhenInUse:
                    return "AuthorizedWhenInUse"
                case .authorizedAlways:
                    return "AuthorizedAlways"
                @unknown default:
                    return "Unknown"
                }
            }
        else {
              return "Location services is not enabled"
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        //self.locationManager.stopUpdatingLocation()
        FileActions1().writeToFile("Error getting location : ")
        if (error != nil) {
            FileActions1().writeToFile(error.description)
            print(error.description)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        self.locationManager.stopUpdatingLocation()
//        let lastLocation = locations.last!
        
        if var lastDate = UserDefaults.standard.value(forKey: "lastLocationTime") as? Date {
            let now = Date()
            lastDate.addTimeInterval(1 * 60) // in seconds
            //print("lastDate: \(lastDate.toString("dd MM yyyy HH:mm:ss"))")
            if lastDate < now {
                print("date is less than now")
                UserDefaults.standard.set(now, forKey: "lastLocationTime")
                updateLocation(manager, didUpdateLocations: locations)
                callServerAPI(location: locations.last!)
            } else {
                print("date is greater than now")
            }
        }
        
        //locationManager.allowDeferredLocationUpdates(untilTraveled: 0, timeout: 5)
        

    }
    func updateLocation (_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        if self.geotification == nil {
            self.geotification = Geotification(identifier: self.region_identifier, cord: lastLocation.coordinate)
            self.stopMonitoring(geotification: Geotification(identifier: self.region_identifier, cord: lastLocation.coordinate))
            self.monitorRegionAtLocation(center: lastLocation.coordinate, identifier: self.region_identifier)
            initialLocation = lastLocation
        }
        let distance = lastLocation.distance(from: initialLocation)
        let str = String(format: "%.1f%@", distance > 1000 ? distance/1000 : distance, distance > 1000 ? "km" : "m")
        print("didUpdateLocations- ", str)
        
        //        UIApplication.shared.applicationState == .active {
        //            manager.stopUpdatingLocation()
        //        }
        //        callDummyApi(location: locationObj)
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion")
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion")
        if let region = region as? CLCircularRegion {
            userExitedRegion(region: region)
            
//             triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        //print("didStartMonitoringFor")
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == CLRegionState.inside {
            print("state: inside")
        } else if state == CLRegionState.outside {
            print("state: outside")
            guard let circularRegion = region as? CLCircularRegion else { return }
            userExitedRegion(region: circularRegion)
//            FileActions().writeToFile("region exited: \(circularRegion.center.latitude):\(circularRegion.center.longitude)")
//            stopMonitoring(geotification: Geotification(identifier: region.identifier, cord: circularRegion.center))
        } else if state == CLRegionState.unknown{
            print("state: unknown")
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined, .restricted, .denied:
            FileActions().writeToFile("Loc authorization status changed to Not accessible")
        case .authorizedAlways:
            FileActions().writeToFile("Loc authorization status changed to authorized Always")
        case .authorizedWhenInUse:
            FileActions().writeToFile("Loc authorization status changed to authorized When In Use")
        @unknown default:
            FileActions().writeToFile("Loc authorization status change error occured")
        }
        
    }
}



extension Data {
    func toJSON () -> [String: Any]?{
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
    
    var toString: String {
        return String(decoding: self, as: UTF8.self)
    }
    var toString1: String? {
        return String(data: self, encoding: .utf8)
    }
    
   
}

extension Dictionary {
    var toString: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
        options: [.prettyPrinted]) else { return nil }

        return String(data: theJSONData, encoding: .utf8)
    }
    var toData: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                    options: [.prettyPrinted]) else { return nil }

        return data
    }
}

extension Array {
    var toData: Data? {
//        return NSKeyedArchiver.archivedData(withRootObject: self)
        guard let data = try? JSONSerialization.data(withJSONObject: self) else { return nil }
        return data
    }
}
