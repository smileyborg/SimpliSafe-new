//
//  AppDelegate.m
//  SimpliSafe
//
//  Created by Scott Newman on 7/12/14.
//  Copyright (c) 2014 Newman Creative. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkReachabilityManager.h"

#import "SSAPIClient.h"
#import "SSUserManager.h"
#import "Constants.h"
#import "SimpliSafe-Swift.h"

@interface AppDelegate ()

@property (nonatomic, strong) GeofenceManager *geofenceManager;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureAppearance];
    
    // Start the reachability manager so we can check for network connections
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
    {
        // If the status is greater than zero, the network is reachable
        [[SSUserManager sharedManager] setNetworkIsReachable:(status > 0)];
        [[SSAPIClient sharedClient] setNetworkIsReachable:(status > 0)];
    }];
    
    // Set up the geofence manager at app launch so that we'll be able to handle notifications when the app is launched due to
    // a region entry/exit event.
    self.geofenceManager = [[GeofenceManager alloc] initWithHandler:^(BOOL entered) {
        NSString *desiredStateName = entered ? @"off" : @"away";
        SSUserManager *userManager = [SSUserManager sharedManager];
        NSAssert(userManager.lastSessionToken, @"Geofence Boundary Handler: No last session token!");
        NSAssert(userManager.user, @"Geofence Boundary Handler: No user!");
        SSAPIClient *client = [SSAPIClient sharedClient];
        [client changeStateForLocation:userManager.currentLocation
                                  user:userManager.user
                                 state:desiredStateName
                            completion:^(SSSystemState systemState, NSError *error) {
                                
                            }];
    }];
    
    return YES;
}

- (void)configureAppearance
{
    // Make the segmented control pale blue
    [[UISegmentedControl appearance] setTintColor:kSSPaleBlueColor];

    // Make the bar button items white
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    
    // Make the nav bar tint color white and the background blue
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:kSSPaleBlueColor];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    
    // Set the tab bar tint color to blue
    [[UITabBar appearance] setTintColor:kSSPaleBlueColor];
    
    // Set the accessory view tint color to blue
    [[UITableViewCell appearance] setTintColor:kSSPaleBlueColor];
    
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
