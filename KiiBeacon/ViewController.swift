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
    private var region:CLBeaconRegion? = nil
    private var unknownRangeCont:Int = 0;
    private var unknownRangeIgnoreCount:Int = 5;

    // SettingBundleに設定したDefault値はUserDefaultsから取れない。アホか？
    func initSettings() {
        var appDefaults = Dictionary<String, Any>()
        appDefaults["beaconUUID"] = "48534442-4C45-4144-80C0-1800FFFFFFFF"
        appDefaults["unknownRangeIgnoreCount"] = "5"

        UserDefaults.standard.register(defaults: appDefaults)
        UserDefaults.standard.synchronize()
    }

    func initRegion() {
        let beaconUUID:String = UserDefaults.standard.value(forKey: "beaconUUID") as! String
        print("beacon UUID: \(beaconUUID)")
        let uuid:UUID = UUID(uuidString: beaconUUID)!;

        region = CLBeaconRegion(proximityUUID: uuid, identifier: "Beacon Test")
        region!.notifyEntryStateOnDisplay = false
        region!.notifyOnEntry = true
        region!.notifyOnExit = true
    }

    func setUnkownRangeIgnoreCount() {
        let unknownRangeIgnoreCountStr = UserDefaults.standard.value(forKey: "unknownRangeIgnoreCount") as! String
        Int(unknownRangeIgnoreCountStr).map { (w) in
            unknownRangeIgnoreCount = w
        }
    }

    func startMonitoringIfAllowed() {
        if (notificationSwitch.selectedSegmentIndex == 0) {
            let status = CLLocationManager.authorizationStatus()
            if (status != CLAuthorizationStatus.authorizedAlways) {
                locationManager.requestAlwaysAuthorization()
            } else {
                print ("Already authorized. start monitoring");
                startMonitoring(manager: locationManager);
            }
        } else {
            stopMonitoring(manager: locationManager)
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
        }
    }

    internal func onLoad() {
        initRegion()
        setUnkownRangeIgnoreCount()
        startMonitoringIfAllowed()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        ((UIApplication.shared.delegate) as! AppDelegate).viewController = self

        initSettings()
        onLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopRangingBeacon()
        super.viewWillDisappear(animated)
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
            locationManager.stopRangingBeacons(in: region!)
            stopMonitoring(manager: locationManager)
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
        }
    }

    private func stopMonitoring(manager:CLLocationManager) {
        for r in locationManager.monitoredRegions {
            manager.stopMonitoring(for: r)
        }
    }

    private func startMonitoring(manager:CLLocationManager) {
        initRegion()
        for r in manager.monitoredRegions {
            let beaconRegion:CLBeaconRegion = r as! CLBeaconRegion
            if (beaconRegion.proximityUUID != region?.proximityUUID) {
                manager.stopMonitoring(for: beaconRegion)
            }
        }
        manager.startMonitoring(for: region!)
        manager.requestState(for: region!)
    }

    private func startRangingBeacon() {
        unknownRangeCont = 0;
        locationManager.startRangingBeacons(in: region!)
    }

    private func stopRangingBeacon() {
        unknownRangeCont = 0;
        locationManager.stopRangingBeacons(in: region!)
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
                unknownRangeCont += 1
                proximityText.text = "unknown"
                break;
            case CLProximity.far:
                unknownRangeCont = 0
                proximityText.text = "far"
                break;
            case CLProximity.near:
                unknownRangeCont = 0
                proximityText.text = "near"
                break;
            case CLProximity.immediate:
                unknownRangeCont = 0
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
            print ("inside")
            proximityState.selectedSegmentIndex = 0
            startRangingBeacon()
            break;
        case CLRegionState.outside:
            print ("outside")
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
            stopRangingBeacon()
            break;
        case CLRegionState.unknown:
            print ("unknown")
            proximityState.selectedSegmentIndex = 1
            proximityText.text = "---"
            stopRangingBeacon()
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

