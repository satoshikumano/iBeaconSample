//
//  AppDelegate.swift
//  KiiBeacon
//
//  Created by satoshi on 2016/09/21.
//  Copyright © 2016年 Kii. All rights reserved.
//

import UIKit
import UserNotifications
import KiiSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    internal var viewController: ViewController?

    // Replace with your apps ID, Key and Site.
    private let appID = "{Your App ID}"
    private let appKey = "{Your App Key}"
    private let appSite = KiiSite.JP

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerNotification(application: application)
        Kii.begin(withID: appID, andKey: appKey, andSite: appSite)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        viewController?.onLoad()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerNotification(application:UIApplication) {
        if #available(iOS 10.0, *) {
            let action = UNNotificationAction(identifier: "launch", title: "Launch app", options: [UNNotificationActionOptions.foreground])
            let category = UNNotificationCategory(identifier: "launchCategory", actions: [action], intentIdentifiers: [], options: [])
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
                if ((error) != nil || !granted) {
                    return
                }
                center.setNotificationCategories([category])
            }
        } else {
            let action = UIMutableUserNotificationAction()
            action.identifier = "launc"
            action.title = "Launch app"
            action.activationMode = UIUserNotificationActivationMode.foreground
            action.isAuthenticationRequired = false
            action.isDestructive = true

            let category = UIMutableUserNotificationCategory()
            category.identifier = "launchCategory"
            category.setActions([action], for: UIUserNotificationActionContext.minimal)
            category.setActions([action], for: UIUserNotificationActionContext.default)

            let settings = UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: [category])
            application.registerUserNotificationSettings(settings);
        }
        
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .sound])
    }

}

