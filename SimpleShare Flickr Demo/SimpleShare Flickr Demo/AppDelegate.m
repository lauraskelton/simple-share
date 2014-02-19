//
//  AppDelegate.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "AppDelegate.h"
#import "SimpleShare.h"
#import "MyPhotosViewController.h"

#define kPhotosArrayKey @"SimpleSharePhotosArrayKey"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
#warning add a unique UUID for your app here. you can create one here: http://www.uuidgenerator.net
    [SimpleShare sharedInstance].simpleShareAppID = @"your-uuid-goes-here";
    
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    MyPhotosViewController *mainController = (MyPhotosViewController *)navController.topViewController;
    
    NSMutableArray *myPhotosArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kPhotosArrayKey] mutableCopy];
    
    mainController.myPhotoIDs = myPhotosArray;
    myPhotosArray = nil;
    
    mainController = nil;
    navController = nil;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"application did enter background with ids: %@", [SimpleShare sharedInstance].myItemIDs);
    [[NSUserDefaults standardUserDefaults] setObject:[SimpleShare sharedInstance].myItemIDs forKey:kPhotosArrayKey];

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    MyPhotosViewController *mainController = (MyPhotosViewController *)navController.topViewController;
    
    NSMutableArray *myPhotosArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kPhotosArrayKey] mutableCopy];
    
    mainController.myPhotoIDs = myPhotosArray;
    myPhotosArray = nil;
    
    mainController = nil;
    navController = nil;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@"application will terminate with ids: %@", [SimpleShare sharedInstance].myItemIDs);
    [[NSUserDefaults standardUserDefaults] setObject:[SimpleShare sharedInstance].myItemIDs forKey:kPhotosArrayKey];
}

@end
