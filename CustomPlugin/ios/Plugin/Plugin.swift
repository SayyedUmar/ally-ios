import Foundation
import Capacitor
//import UIKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CustomPlugin)
public class CustomPlugin: CAPPlugin {

    var timer: Timer!
    @objc func echo(_ call: CAPPluginCall) {
//        self.call = call
//        if timer == nil {setTimer()}
        let value = call.getString("value") ?? ""
        let person = call.getObject("person")
        
        call.success([
            "value": Date().toString("dd MM YY HH:mm:ss")
        ])
        
        NotificationCenter.default.post(
                 name: NSNotification.Name.init(value),
                 object: self,
                 userInfo: person)
        
        SwiftEventBus.onMainThread(self, name: "onLocationCapture") { result in
            guard let result = result, let userInfo = result.userInfo as? [String : Any] else {return}
            print("onLocationCapture", userInfo)
            self.notifyListeners("onLocationCapture", data: ["date": Date().toString("dd MM yyyy HH:mm:ss"),
                                                         "lat": userInfo["lat"] as! Double, "lng": userInfo["lng"] as! Double])
        }
    }
    
    func setTimer () {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(CustomPlugin.resolve), userInfo: nil, repeats: true)
        }
    }
    
    @objc func resolve() {
        DispatchQueue.global().async {
            self.notifyListeners("myPluginEvent", data: ["value": Date().toString("dd MM yyyy HH:mm:ss")])
        }
        
    }
    
    deinit  {
        
        print("CAPPluginCall deinit")
    }

}



extension Date {

    var fullDate: String   { localizedDescription(dateStyle: .full,   timeStyle: .none) }
    var longDate: String   { localizedDescription(dateStyle: .long,   timeStyle: .none) }
    var mediumDate: String { localizedDescription(dateStyle: .medium, timeStyle: .none) }
    var shortDate: String  { localizedDescription(dateStyle: .short,  timeStyle: .none) }

    var fullTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .full) }
    var longTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .long) }
    var mediumTime: String { localizedDescription(dateStyle: .none,   timeStyle: .medium) }
    var shortTime: String  { localizedDescription(dateStyle: .none,   timeStyle: .short) }

    var fullDateTime: String   { localizedDescription(dateStyle: .full,   timeStyle: .full) }
    var longDateTime: String   { localizedDescription(dateStyle: .long,   timeStyle: .long) }
    var mediumDateTime: String { localizedDescription(dateStyle: .medium, timeStyle: .medium) }
    var shortDateTime: String  { localizedDescription(dateStyle: .short,  timeStyle: .short) }
}

extension Date {
    func localizedDescription(dateStyle: DateFormatter.Style = .medium,
                              timeStyle: DateFormatter.Style = .medium,
                           in timeZone : TimeZone = .current,
                              locale   : Locale = .current) -> String {
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
    var localizedDescription: String { localizedDescription() }
    
    func toString (_ format: String) -> String {
        Formatter.date.dateFormat = format
        return Formatter.date.string(from: self)
    }
}

extension TimeZone {
    static let gmt = TimeZone(secondsFromGMT: 0)!
}
extension Formatter {
    static let date = DateFormatter()
}
