import UIKit
import Capacitor
import BackgroundTasks
import Firebase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var operationQueue = OperationQueue()
    let gcmMessageIDKey = "gcm.message_id"
    let locationManager = CLLocationManager()
    let region_identifier = "scram_region_identifier"
    var geotification: Geotification?
    var initialLocation : CLLocation!
    var direction : CLHeading!
    var person: Person!
    
    func detectInvoker(launchOptions:[UIApplication.LaunchOptionsKey: Any]?) {
        if (launchOptions != nil) {
            FileActions().writeToFile("LaunchOptionsKey: ")
            // Launched from push notification
            if let remoteNotifKey = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any]  {
                FileActions().writeToFile("LaunchOptionsKey_remoteNotification: "+remoteNotifKey.toString!)
            } else if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] {
                FileActions().writeToFile("LaunchOptionsKey_location: ")
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.detectInvoker(launchOptions:launchOptions)
        UIDevice.current.isBatteryMonitoringEnabled = true

        var arr = [""]
        if let ar = UserDefaults.standard.array(forKey: "MY_AARY") {
            arr = ar as! [String]
        }
        if let _ = UserDefaults.standard.value(forKey: "lastLocationTime") as? Date {
            
        } else {
            UserDefaults.standard.set(Date(), forKey: "lastLocationTime")
        }

        UserDefaults.standard.setValue(arr, forKey: "MY_AARY")
        print("didFinishLaunchingWithOptions", arr)
        
        //registerBackgroundTaks()
        //UIApplication.shared.setMinimumBackgroundFetchInterval(20)
        //UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        FileActions().readFromFile()
        self.setUpFirebase(app: application)
        self.requestPermission()
        
        //        self.callDummyApi1()
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
//            for i in 0...10 {
//                print("printing Log : \(i)")
//            }
//            self.startLocationUpdate()
//            self.scheduleLocalNotification(title: "LocalNotif", body: "body", info: nil)
        }
//        self.startLocationUpdate()
        self.subscribeBusEvents()
        return true
    }
    
    func setUpFirebase (app:UIApplication) {
        //Access the registration token

        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,completionHandler: {granted, _ in
                    if granted {
                        print("notificationCenter Permission granted: \(granted)") // 3
                        guard granted else {   return}
                        DispatchQueue.main.async {
                            self.getNotificationSettings()
                        }
                    } else {
                        print("notificationCenter Permission denied: \(granted)") // 3
                    }
            })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            app.registerUserNotificationSettings(settings)
        }
        app.registerForRemoteNotifications()
        
        
        //        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FileActions().writeToFile("app entered in background")
//        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
//            print("significantLocationChangeMonitoringAvailable")
//            locationManager.startMonitoringSignificantLocationChanges()
//        }
        if #available(iOS 13.0, *) {
//            self.cancelAllPandingBGTask()
//            self.scheduleAppRefresh()
//            self.scheduleAppProcessing()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //FileActions().writeToFile("app entered in foreground_1")
        print("app entered in foreground_1")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        connectToFcm()
        print("app entered in foreground_2")
        FileActions().writeToFile("app entered in foreground_2")
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        FileActions().writeToFile("applicationWillTerminate")
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        FileActions().writeToFile("applicationDidReceiveMemoryWarning")
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Called when the app was launched with a url. Feel free to add additional processing here,
        // but if you want the App API to support tracking app url opens, make sure to keep this call
        return CAPBridge.handleOpenUrl(url, options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when the app was launched with an activity, including Universal Links.
        // Feel free to add additional processing here, but if you want the App API to support
        // tracking app url opens, make sure to keep this call
        return CAPBridge.handleContinueActivity(userActivity, restorationHandler)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let statusBarRect = UIApplication.shared.statusBarFrame
        guard let touchPoint = event?.allTouches?.first?.location(in: self.window) else { return }
        
        if statusBarRect.contains(touchPoint) {
            NotificationCenter.default.post(CAPBridge.statusBarTappedNotification)
        }
    }
    
    #if USE_PUSH
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        print("deviceToken", deviceToken.hexString)
        Messaging.messaging().apnsToken = deviceToken
        //Messaging.messaging().subscribe(toTopic: "ios_tech_ally_poc")
        NotificationCenter.default.post(name: Notification.Name(CAPNotifications.DidRegisterForRemoteNotificationsWithDeviceToken.name()), object: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: Notification.Name(CAPNotifications.DidFailToRegisterForRemoteNotificationsWithError.name()), object: error)
    }
    
    #endif
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("performFetchWithCompletionHandler initiated")
        // write your code
        //        if let newData = fetchUpdates() {
        //           addDataToFeed(newData: newData)
        //           completionHandler(.newData)
        //        }
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification", userInfo)
        
        if(application.applicationState == UIApplication.State.active) {
            //app is currently active, can update badges count here
            FileActions1().writeToFile("didReceiveRemoteNotification_UIApplicationStateActive")
        }else if(application.applicationState ==  UIApplication.State.background){
            //app is in background, if content-available key of your notification is set to 1, poll to your backend to retrieve data and update your interface here
            FileActions1().writeToFile("didReceiveRemoteNotification_UIApplicationStateBackground")
            self.startLocationUpdate()
        }else if(application.applicationState ==  UIApplication.State.inactive){
            //app is transitioning from background to foreground (user taps notification), do what you need when user taps here
            FileActions1().writeToFile("didReceiveRemoteNotification_UIApplicationStateInactive")
        }
    }
}



extension Date {
    func toString (_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    func toUTCString (_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: self)
    }
   
    static func toDate (date: String, format: String)  -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: date)
    }
}

extension String {
    func toDate (format: String)  -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}

extension AppDelegate {
    
    func connectToFcm(){
//        Messaging.messaging().connect
//        FirebaseApp.message.connectWithCompletion { (error) in
//                if (error != nil){print("Unable to connect with FCM. \(error)")}
//                else {print("Connected to FCM.")}
//        }
    }
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func registerBackgroundTaks() {
        
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ionic.example.timer.count", using: nil){task in
                //self.scheduleLocalNotification(title: "Ally", body: "App Refreshed- BGAppRefreshTask", info: nil)
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ionic.example.timer.count.processing", using: nil){task in
                //self.scheduleLocalNotification(title: "Ally", body: "App Refreshed- BGProcessingTask", info: nil)
                self.handleAppProcessing(task: task as! BGProcessingTask)
            }
        } else {
            // Fallback on earlier versions
            // UIApplication.shared.setMinimumBackgroundFetchInterval(20)
            // UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
    }
    
    @available(iOS 13.0, *)
    func handleAppProcessing (task: BGProcessingTask) {
        self.scheduleAppProcessing()
        FileActions().writeToFile("handleAppProcessing")
        //self.startLocationUpdate()
        let operation = BlockOperation(block: {
            self.saveDateInStorage()
        }) // RefreshAppContentsOperation()
        
        task.expirationHandler = {
            //            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        operationQueue.addOperation(operation)
    }
    
    
    
    
    @available(iOS 13.0, *)
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleAppRefresh()

        // Create an operation that performs the main part of the background task
        FileActions().writeToFile("handleAppRefresh")
        //self.startLocationUpdate()
        let operation = BlockOperation() // RefreshAppContentsOperation()
        operation.addExecutionBlock { print("operation executing") }
        operation.addExecutionBlock { self.saveDateInStorage() }
        operationQueue.addOperations([operation], waitUntilFinished: true)
        
        // Provide an expiration handler for the background task
        // that cancels the operation
        task.expirationHandler = {
            //            operation.cancel()
        }
        
        // Inform the system that the background task is complete
        // when the operation completes
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        // Start the operation
        
    }
    
    func saveDateInStorage() {
//        print("saveDateInStorage")
//        var arr = [""]
//        if let ar = UserDefaults.standard.array(forKey: "MY_AARY") {
//            arr = ar as! [String]
//        }
//        arr.append(Date().toString("dd MM YY HH:mm:ss"))
//        UserDefaults.standard.setValue(arr, forKey: "MY_AARY")
//        print("saveDateInStorage", arr)
    }
    
    @available(iOS 13.0, *)
    func scheduleAppProcessing () {
        let request = BGProcessingTaskRequest(identifier: "com.ionic.example.timer.count.processing")
        request.requiresNetworkConnectivity = true // Need to true if your task need to network process. Defaults to false.
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1*60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule image featch: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh () {
        let request = BGAppRefreshTaskRequest(identifier: "com.ionic.example.timer.count")
        // Fetch no earlier than 15 minutes from now, 15 * 60
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1*60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func cancelAllPandingBGTask() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancelAllTaskRequests()
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    
}



//MARK:- Notification Helper

extension AppDelegate {
    
    func registerLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (granted, error) in
            if granted {
                print("notificationCenter Permission granted: \(granted)") // 3
            } else {
                print("notificationCenter Permission denied: \(granted)") // 3
            }
        }
    }
    
    func scheduleLocalNotification(title: String, body: String, info: [AnyHashable: Any]?) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            //print("Notification settings: \(settings)")
            if settings.authorizationStatus == .authorized {
                self.fireNotification(title: title, body: body, info: info)
            }
        }
    }
    
    func fireNotification(title: String, body: String, info: [AnyHashable: Any]?) {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = title
        notificationContent.body = body
        
        if let info = info {
            notificationContent.userInfo = info
        }
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "local_notification"+UUID().uuidString, content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("FCMToken: \(fcmToken)")
        InstanceID.instanceID().instanceID { (result, error) in
          if let error = error {
            print("Error fetching remote instance ID: \(error)")
          } else if let result = result {
            print("Remote instance ID token: \(result.token)")
//            self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
          }
        }

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("messaging", messaging.fcmToken)
    }
    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("willPresentUserNotificationCenter Message ID: \(messageID)")
        }
        //sdebugPrint("didReceiveUserNotificationCenter\(userInfo)")

        // Change this to your preferred presentation option
        completionHandler([.alert,.badge,.sound])
    }
    
    //TAP on notification hanlder
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("didReceiveUserNotificationCenter Message ID: \(messageID)")
        }
        //Helpshift implementation
        
        
        // Print full message.
        debugPrint("didReceiveUserNotificationCenter\(userInfo)")
        if let payload = userInfo["aps"] as? [AnyHashable: Any] {
            if (payload["alert"] as? [AnyHashable: Any]) != nil{
                if let tripId = userInfo[""] as? String {
                }
            }
        }
        
        completionHandler()
    }
    
}
