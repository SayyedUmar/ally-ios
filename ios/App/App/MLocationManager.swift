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
    func callDummyApi1 () {
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let data = data, error == nil
                else { return }
            print("data = ",data.toJSON())
        }.resume()
    }
    
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            print("monitorRegionAtLocation", region.identifier)
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == geotification.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func monitorRegionAtLocation (center: CLLocationCoordinate2D, identifier: String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("monitorRegionAtLocation")
            let maxDistance = locationManager.maximumRegionMonitoringDistance
            let region = CLCircularRegion(center: center,
                                          radius: 50/*in meters*/, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
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
        
        if let lastDate = UserDefaults.standard.value(forKey: "lastLocationTime") as? String {
            let now = Date()
            var date = lastDate.toDate(format: "dd MM yyyy, HH:mm:ss")!
            date.addTimeInterval(1*60)
            if date < now {
                
            } else {
                
            }
        }
        
        //locationManager.allowDeferredLocationUpdates(untilTraveled: 0, timeout: 5)
        updateLocation(manager, didUpdateLocations: locations)

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
            FileActions().writeToFile("region exited: \(region.center.latitude):\(region.center.longitude)")
            stopMonitoring(geotification: Geotification(identifier: region.identifier, cord: region.center))
            //self.startLocationUpdate()
            // triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
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
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .utf8)
    }
}
