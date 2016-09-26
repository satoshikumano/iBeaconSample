//
//  ViewController.swift
//  KiiBeacon
//
//  Copyright © 2016年 Kii. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var notificationSwitch: UISegmentedControl!

    @IBOutlet weak var proximityState: UISegmentedControl!

    @IBOutlet weak var proximityText: UITextField!

    private let locationManager: CLLocationManager = CLLocationManager()
    private let uuid:UUID! = UUID(uuidString: "48534442-4C45-4144-80C0-1800FFFFFFFF")!
    private var region:CLBeaconRegion? = nil

    private var isRanging:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        region = CLBeaconRegion(proximityUUID: uuid, identifier: "Beacon Test")
        region!.notifyEntryStateOnDisplay = false
        region!.notifyOnEntry = true
        region!.notifyOnExit = true

        // Don't allow to switch.
        proximityState.isUserInteractionEnabled = false

        let status = CLLocationManager.authorizationStatus()
        if (status != CLAuthorizationStatus.authorizedAlways) {
            locationManager.requestAlwaysAuthorization()
        } else {
            print ("Already authorized. start monitoring");
            startMonitoring(manager: locationManager);
            locationManager.requestState(for: region!)
        }
        if (notificationSwitch.selectedSegmentIndex == 0) {
            locationManager.requestState(for: region!)
        } else {
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func notificationSettingChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if (index == 0) { // Turned on.
            let status = CLLocationManager.authorizationStatus()
            if (status != CLAuthorizationStatus.authorizedAlways) {
                locationManager.requestAlwaysAuthorization()
            } else {
                print ("Already authorized. start monitoring");
                startMonitoring(manager: locationManager);
            }
        } else { // Turned off.
            stopMonitoring(manager: locationManager)
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
        }
    }

    private func stopMonitoring(manager:CLLocationManager) {
        manager.stopMonitoring(for: region!)
    }

    private func startMonitoring(manager:CLLocationManager) {
        manager.startMonitoring(for: region!)
    }

    func sendNotification(title:String, body:String) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
            content.categoryIdentifier = "launchCategory"
            content.sound = UNNotificationSound.default()
            let request = UNNotificationRequest(identifier: "test", content: content, trigger: nil);
            let current = UNUserNotificationCenter.current()
            current.add(request) { (e: Error?) in
                if (e != nil) {
                    withVaList(e as! [CVarArg]!) { NSLogv("Failed to send notification. ", $0)}
                }
            };
        } else {
            // Fallback on earlier versions
            let notification = UILocalNotification()
            notification.fireDate = Date()
            notification.timeZone = NSTimeZone.default
            notification.alertTitle = title;
            notification.alertBody = body;
            notification.category = "launchCategory"
            UIApplication.shared.scheduleLocalNotification(notification);
        };

    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print ("didChangeAuthorization")
        switch(status) {
        case .authorizedAlways:
            startMonitoring(manager: manager);
            break;
        case .authorizedWhenInUse:
            break;
        case .denied:
            break;
        case .notDetermined:
            break;
        case .restricted:
            break;
        }
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if (beacons.count > 0) {
            let proximity = beacons[0].proximity
            switch (proximity) {
            case CLProximity.unknown:
                proximityText.text = "unknown"
                break;
            case CLProximity.far:
                proximityText.text = "far"
                break;
            case CLProximity.near:
                proximityText.text = "near"
                break;
            case CLProximity.immediate:
                proximityText.text = "immediate"
                break;
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print ("Started monitoring")
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print ("Determined state: \(state.rawValue)")
        switch (state) {
        case CLRegionState.inside:
            proximityState.selectedSegmentIndex = 0
            manager.startRangingBeacons(in: region as! CLBeaconRegion)
            break;
        case CLRegionState.outside:
            proximityState.selectedSegmentIndex = 1
            manager.stopRangingBeacons(in: region as! CLBeaconRegion)
            break;
        case CLRegionState.unknown:
            proximityState.selectedSegmentIndex = 1
            manager.stopRangingBeacons(in: region as! CLBeaconRegion)
            break;
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed monitoring \(error)")
        proximityState.selectedSegmentIndex = 1
        proximityText.text = "Monitoring failed."
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sendNotification(title: "立ち去りました。", body: "アプリを開く")
        proximityState.selectedSegmentIndex = 1
        proximityText.text = "---"
        print("Exit region: " + region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(title: "近いです。", body: "アプリを開く")
        proximityState.selectedSegmentIndex = 0
        manager.startRangingBeacons(in: region as! CLBeaconRegion)
        print("Enter region: " + region.identifier)
    }
}

