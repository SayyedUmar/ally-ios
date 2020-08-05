//
//  MLocationManager.swift
//  App
//
//  Created by Umar on 30/07/20.
//

import Foundation
import CoreLocation
import UIKit


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
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func startLocationUpdate(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = CLActivityType.automotiveNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startUpdatingLocation()
        
        
    }
    
    func callDummyApi (location: CLLocation) {
        let coord = location.coordinate
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let data = data, error == nil
                else { return }
            let dic = data.toJSON()
            
            FileActions().writeToFile("\(dic?["title"]!) Lat -\(coord.latitude) | Long - \(coord.longitude)")
            
        }.resume()
    }
    func callServerAPI (location: CLLocation) {
        let url = URL(string: "https://allymobileapigateway.scramstage.com/api/v1/NativeMobile/Location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = getPostData(location: location).toData
        print("location- ", location.coordinate.latitude, location.coordinate.longitude)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let data = data, error == nil
                else { return }
            print("after response")
            print("statusCode = ", httpURLResponse.statusCode )
        }.resume()
    }
    
    func getPostData (location: CLLocation) -> [[String: Any]] {
        return [[
            "victimId": "B08FFE14-1AB0-4321-A46D-98E8FC74AA71",
            "deviceImei": "bcf7b96dbdefbde1",
            "timestamp": Date().toUTCString("yyyy-MM-dd'T'hh:mm:ss.SSS'Z'"),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "altitudeAccuracy": location.verticalAccuracy,
            "direction": 0,
            "speed": location.speed,
            "satellite": 0,
            "csq": 0,
            "isMoving": false, //calculated based on activityType
            "fix": 0, //zero
            "address": "address",
            "locationMode": "A",
            "eventType": "Location",
            "cacheTimeStamp": Date().toUTCString("yyyy-MM-dd'T'hh:mm:ss.SSS'Z'"),
            "activityType": "activityType",
            "activityConfidence": -1,
            "batteryLevel": 93, //UIDevice.current.batteryLevel,
            "isBatteryCharging": false,
        ]]
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
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
    
}

extension AppDelegate: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        self.locationManager.stopUpdatingLocation()
        if (error != nil) {
            print(error.description)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        self.locationManager.stopUpdatingLocation()
//        let lastLocation = locations.last!
        
        if var lastDate = UserDefaults.standard.value(forKey: "lastLocationTime") as? Date {
            let now = Date()
            lastDate.addTimeInterval(10) // in seconds
            if lastDate < now {
                print("date is less than now", Date().toUTCString("yyyy-MM-dd'T'hh:mm:ss.SSS'Z'"))
                UserDefaults.standard.set(now, forKey: "lastLocationTime")
                updateLocation(manager, didUpdateLocations: locations)
                //callServerAPI(location: locations.last!)
            } else {
//                print("date is greater than now")
            }
        }
        
        //locationManager.allowDeferredLocationUpdates(untilTraveled: 0, timeout: 5)
        

    }
    func updateLocation (_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        if self.geotification == nil {
            self.geotification = Geotification(identifier: self.region_identifier, cord: lastLocation.coordinate)
            //self.stopMonitoring(geotification: Geotification(identifier: self.region_identifier, cord: locationObj.coordinate))
            self.monitorRegionAtLocation(center: lastLocation.coordinate, identifier: self.region_identifier)
            initialLocation = lastLocation
        }
        let distance = lastLocation.distance(from: initialLocation)
        let str = String(format: "%.1f%@", distance > 1000 ? distance/1000 : distance, distance > 1000 ? "km" : "m")
        print("didUpdateLocations - ", str)
        
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
            
            //let identifier = region.identifier
            //self.region = region
            userExitedRegion(region: region)
            
//             triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("didStartMonitoringFor")
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
