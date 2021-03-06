//
//  AppDelegate.swift
//  mediawave
//
//  Created by George Zinyakov on 12/22/15.
//  Copyright © 2015 George Zinyakov. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var trackViewController:GZTrackViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let feedController = storyboard.instantiateViewControllerWithIdentifier("feedController") as! GZTabBarController
        for viewController:UIViewController in feedController.viewControllers!
        {
            if (viewController.restorationIdentifier == "trackViewController") {
                trackViewController = viewController as? GZTrackViewController
            }
        }
        
        if let window = self.window {
            
            var selectedTagsArray:Array<GZLFTag> = Array<GZLFTag>()
            // trying to fetch keys in ns user defaults
            for ( var i=0 ; i < 5 ; i++ ) {
                if ( NSUserDefaults.standardUserDefaults().objectForKey("tag\(i)") != nil) {
                    let awakeData = NSUserDefaults.standardUserDefaults().objectForKey("tag\(i)") as! NSString
                    let selectedTag:GZLFTag = GZLFTag(nameValue: awakeData as String)
                    selectedTagsArray.append(selectedTag)
                    print("tag \(selectedTag.name) index tag\(i)")
                }
                else {
                    // objectForKey is nil
                }
            }
            
            // if selectedTagsArray exists on memory
            if (selectedTagsArray.count != 0) {
                // so our root vc is feed controller inside the tab bar controller
                let mainNavController = storyboard.instantiateViewControllerWithIdentifier("tabBarNavController") as! UINavigationController
                window.rootViewController = mainNavController
                mainNavController.setViewControllers([feedController], animated: true)
                for viewController:UIViewController in feedController.viewControllers!  {
                    if (viewController.restorationIdentifier == "feedNavController") {
                        let feedNavController = viewController as! UINavigationController
                        let tracklistsController = feedNavController.topViewController as! GZFeedViewController
                        tracklistsController.selectedTags = selectedTagsArray
                        print(tracklistsController.selectedTags.count)
                    }
                }
            }
            else {
                let mainNavController = storyboard.instantiateViewControllerWithIdentifier("tagsNavController") as! UINavigationController
                window.rootViewController = mainNavController
            }
            
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        guard ( trackViewController != nil ) else {
            return
        }
        if ( trackViewController!.isPlaying ) {
            trackViewController?.youtubePlayer.playVideo()
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        guard ( trackViewController != nil ) else {
            return
        }
        if ( trackViewController!.isPlaying ) {
            trackViewController?.youtubePlayer.playVideo()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Zinyakov.CoreDataLesson2" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("GZMediaData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

