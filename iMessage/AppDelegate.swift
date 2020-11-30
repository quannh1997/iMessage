//
//  AppDelegate.swift
//  iMessage
//
//  Created by Quan Nguyen on 10/9/20.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "LoginViewController", bundle: nil)
        let navigationController:UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        let rootViewController:UIViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as UIViewController
        navigationController.viewControllers = [rootViewController]
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        return true
    }
}

