//
//  AppDelegate.swift
//  Managee
//
//  Created by Fan Wu on 9/17/16.
//  Copyright © 2016 8184. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //fetch the current view controller
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topViewController(base: presented) }
        return base
    }
    
    class func activate(extraCompletion: (() -> Void)?) {
        //observer action, when it will get called when it triggered
        func actionForObserver() {
            AppDelegate.topViewController()?.pushAlertForSimultaneouslyLogin {
                curUser?.inactivate()
                AppDelegate.activate(extraCompletion: nil)
            }
        }
        
        //completion of successful activating
        func successfulCompletion() { AppDelegate.topViewController()?.loadData() }
        
        //load the login view if the user hasn't loggin yet
        if curUser == nil, let userID = dataService.currentUserID {
            curUser = CurrentUser(key: userID)
        } else { AppDelegate.topViewController()?.goToLoginView() }
        
        //set up the observer
        let win = UIApplication.shared.windows.last!
        curUser?.activate(observerAction: { actionForObserver() }, completion: { (errMsg) in
            if let m = errMsg { ProgressHud.message(to: win, msg: m) } else {
                successfulCompletion()
                extraCompletion?()
            }
        })
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        curUser?.inactivate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppDelegate.activate(extraCompletion: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

