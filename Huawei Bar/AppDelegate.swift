//
//  AppDelegate.swift
//  Huawei Bar
//
//  Created by Mac Mini on 30/04/2016.
//  Copyright © 2016 WisdomSky. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SimplePingDelegate {

    var host = "192.168.8.1"
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var viewMessages: NSMenuItem!
    @IBOutlet weak var currentWIFIUsers: NSMenuItem!
    @IBOutlet weak var signalStrenth: NSMenuItem!
    @IBOutlet weak var batteryPercentage: NSMenuItem!
    @IBOutlet weak var connectionSpeed: NSMenuItem!
    @IBOutlet weak var downloadedSize: NSMenuItem!
    @IBOutlet weak var uploadedSize: NSMenuItem!
    @IBOutlet weak var mobileCarrier: NSMenuItem!
    @IBOutlet weak var mobileData: NSMenuItem!
    @IBOutlet weak var mobileNumber: NSMenuItem!
    
    
    
    var mobile_data_connected = 0
    var pingok = false
    var canstartping = false
    
    @IBAction func viewMessages(sender: NSMenuItem) {
        if let checkURL = NSURL(string: "http://"+self.host+"/html/smsinbox.html") {
            NSWorkspace.sharedWorkspace().openURL(checkURL)
        }
    }
    
    @IBAction func wisdomSky(sender: NSMenuItem) {
        if let checkURL = NSURL(string: "http://facebook.com/WisdomSky") {
            NSWorkspace.sharedWorkspace().openURL(checkURL)
        }
    }
    
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.menu = statusMenu
        self.notifications()
        self.status()
        self.trafficStatus()
        self.mobileDataStatus()
        self.carrierStatus()
    
        
//        for i in 0...255 {
//            for i2 in 0...255 {
//
                backgroundThread(0, background: {
                    
                    let pinger = SimplePing(hostName: "192.168.251.1")
                    pinger.delegate = self;
                    pinger.start()
                    
                    repeat {
                        if (self.pingok) {
                            break
                        }
//                        if (self.canstartping) {
//                            print("looping")
//                            pinger.sendPingWithData(nil)
//                        }
//                        
                        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture() )
                    } while(pinger != nil)
                })
//
//            
//            }
//        }
        
    }
    
    func backgroundThread(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            if(background != nil){ background!(); }
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue()) {
                if(completion != nil){ completion!(); }
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
        print("wew")
        if (self.canstartping) {
            print(pinger.hostName)
            print("FOUND!!!!!!!!!!!!!!!")
            self.pingok = true
        }
        self.canstartping = true
    }
    
    
    func notifications() {
        
        let url = NSURL(string: "http://"+self.host+"/api/monitoring/check-notifications")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if data != nil {
                do {
                    
                    let xmlDoc = try AEXMLDocument(xmlData: data!)
                    
                    let unread = xmlDoc.root["UnreadMessage"].stringValue
                    if (unread == "0") {
                        self.viewMessages.title = "View Messages Inbox"
                    } else {
                        self.viewMessages.title = "View Messages Inbox ("+unread+")"
                    }
                    
                    
                } catch {}
            }
            self.notifications()
        })
        task.resume()
    }
    
    func status() {
        
        let url = NSURL(string: "http://"+self.host+"/api/monitoring/status")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if data != nil {
                do {
                    
                    let xmlDoc = try AEXMLDocument(xmlData: data!)
                    let wifi_users = xmlDoc.root["CurrentWifiUser"].stringValue
                    let total_users = xmlDoc.root["TotalWifiUser"].stringValue
                    self.currentWIFIUsers.title = String("Current WIFI Users: " + wifi_users + "/" + total_users)
                    
                    let signal_strength = xmlDoc.root["SignalStrength"].stringValue
                    self.signalStrenth.title = String("Signal Strength: " + signal_strength + "%")
                    
                    let battery_percentage = xmlDoc.root["BatteryPercent"].stringValue
                    self.batteryPercentage.title = String("Battery Percentage: " + battery_percentage + "%")
                    
                    
                    let mobile_number = xmlDoc.root["msisdn"].stringValue
                    self.mobileNumber.title = String("Mobile: " + mobile_number)
                    
                    
                } catch {}
            }
            self.status()
        })
        
        task.resume()
    }
    
    
    func trafficStatus() {
        
        let url = NSURL(string: "http://"+self.host+"/api/monitoring/traffic-statistics")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if data != nil {
                do {
                    
                    let xmlDoc = try AEXMLDocument(xmlData: data!)
                    
                    
                    let connection_download = String(xmlDoc.root["CurrentDownloadRate"].intValue / 1024) + "kb/s ∇"
                    let connection_upload = String(xmlDoc.root["CurrentUploadRate"].intValue  / 1024) + "kb/s ∆"
                    
                    
                    self.statusItem.title = String(connection_download + " | " + connection_upload)
                    self.connectionSpeed.title = "Speed: " + String(connection_download + " | " + connection_upload)
                    
                    
                    let downloaded = String(xmlDoc.root["CurrentDownload"].intValue  / (1024 * 1024)) + "MB"
                    
                    self.downloadedSize.title = "Downloaded: " + downloaded
                    
                    let uploaded = String(xmlDoc.root["CurrentUpload"].intValue  / (1024 * 1024)) + "MB"
                    self.uploadedSize.title = "Uploaded: " + uploaded
                    
                    
                } catch {}
            }
            self.trafficStatus()
            
        })
        
        task.resume()
    }

    
    func mobileDataStatus() {
        
        let url = NSURL(string: "http://"+self.host+"/api/dialup/mobile-dataswitch")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if data != nil {
                do {
                    
                    let xmlDoc = try AEXMLDocument(xmlData: data!)
                    let mobile_switch = xmlDoc.root["dataswitch"].intValue
                    
                    self.mobileData.title = String("Mobile Data: " + (mobile_switch == 1 ? "On" : "Off"))
                    
                    
                    self.mobileData.state = mobile_switch
                
                    
                } catch {}
            }
            self.mobileDataStatus()
        })
        
        task.resume()
    }

    
    func carrierStatus() {
        
        let url = NSURL(string: "http://"+self.host+"/api/net/current-plmn")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if data != nil {
                do {
                    
                    let xmlDoc = try AEXMLDocument(xmlData: data!)
                    let mobile_carrier = xmlDoc.root["ShortName"].stringValue
                    
                    self.mobileCarrier.title = String("Carrier: " + mobile_carrier)
                 
                    
                    
                    
                } catch {}
            }
            self.carrierStatus()
        })
        
        task.resume()
    }

    

}

