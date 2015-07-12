//
//  AppDelegate.m
//  SimpliSafe
//
//  Created by Scott Newman on 7/12/14.
//  Copyright (c) 2014 Newman Creative. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkReachabilityManager.h"
#import "SimpliSafe-Swift.h"

#import "SSAPIClient.h"
#import "SSUserManager.h"
#import "Constants.h"
#import "SSAlarmManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) GeofenceManager *geofenceManager;

@end

@implementation AppDelegate

+ (void)presentLocalNotificationWithText:(NSString *)notificationText soundOrVibration:(BOOL)soundOrVibration
{
    NSAssert([notificationText length] > 0, @"Attempted to present a nil or empty local notification!");
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = notificationText;
    if (soundOrVibration) {
        notification.soundName = UILocalNotificationDefaultSoundName;
    }
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

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
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound
                                                                                         categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    
    // Set up the geofence manager at app launch so that we'll be able to handle notifications when the app is launched due to
    // a region entry/exit event. When the app is terminated/not in memory and the device enters or exits a geofenced region,
    // the app is launched by the system, and then any CLLocationManagerDelegate (such as the GeofenceManager) will receive the
    // relevant callbacks.
    self.geofenceManager = [[GeofenceManager alloc] initWithHandler:^(BOOL entered)
                            {
                                [SSAlarmManager automaticallySetAlarmState:(entered ? SSSystemStateOff : SSSystemStateAway)
                                                                   success:^(NSString *successText) {
                                                                       [AppDelegate presentLocalNotificationWithText:successText soundOrVibration:YES];
                                                                   }
                                                                     error:^(NSString *errorText) {
                                                                         [AppDelegate presentLocalNotificationWithText:errorText soundOrVibration:YES];
                                                                     }];
                            }
                                                              error:^(CLError error)
                            {
                                NSString *errorMessage = nil;
                                switch (error) {
                                    case kCLErrorRegionMonitoringDenied:
                                        errorMessage = @"Error: Region Monitoring Denied";
                                        break;
                                    case kCLErrorRegionMonitoringFailure:
                                        errorMessage = @"Error: Region Monitoring Failure";
                                        break;
                                    case kCLErrorRegionMonitoringSetupDelayed:
                                        errorMessage = @"Error: Region Monitoring Setup Delayed";
                                        break;
                                    case kCLErrorRegionMonitoringResponseDelayed:
                                        errorMessage = @"Error: Region Monitoring Response Delayed";
                                        break;
                                    default:
                                        errorMessage = [NSString stringWithFormat:@"Error: CLError code %@", @(error)];
                                        break;
                                }
                                [AppDelegate presentLocalNotificationWithText:errorMessage soundOrVibration:YES];
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
