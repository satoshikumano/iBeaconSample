# iBeaconSample
Kii Cloud and iBeacon sample.

## Demonstrated usecase
When approached to the Beacon,
customize the notification depending on the contents on the Kii Cloud.
It can be used for store advertizement, etc.

## Setup

- Edit AppDelegate.swift and replace appID, appKey and appSite with your
application's.

- Edit ViewController.swift and replace defaultBeaconUUID with your beacon's
ID.

## Build
```shell
pod install
```
Open KiiBeacon.xcworkspace and build app.

## Beacon emulation
To emulate beacon with your Mac,
[node-blecon](https://github.com/sandeepmistry/node-bleacon)
can be used.

