//
//  SSAlarmManager.m
//  SimpliSafe
//
//  Created by Tyler Fox on 7/11/15.
//  Copyright (c) 2015 Tyler Fox. All rights reserved.
//

#import "SSAlarmManager.h"

#import "SSUserManager.h"
#import "SSUser.h"

@implementation SSAlarmManager

+ (void)automaticallySetAlarmState:(SSSystemState)newState
                           success:(void (^)(NSString *successText))successHandler
                             error:(void (^)(NSString *errorText))errorHandler
{
    if (newState == SSSystemStateUnknown) {
        NSAssert(newState != SSSystemStateUnknown, @"Attempted to set the alarm to an invalid state.");
        return;
    }
    
    // Declare success and error blocks as local variables to call the success and error handlers passed in with appropriate messages
    void (^successBlock)() = ^{
        if (successHandler) {
            NSString *successMessage = [NSString stringWithFormat:@"Alarm automatically %@.", (newState == SSSystemStateOff ? @"disarmed" : @"armed")];
            successHandler(successMessage);
        }
    };
    void (^errorBlock)() = ^{
        if (errorHandler) {
            NSString *errorMessage = [NSString stringWithFormat:@"Error: Unable to automatically %@ alarm!", (newState == SSSystemStateOff ? @"disarm" : @"arm")];
            errorHandler(errorMessage);
        }
    };
    
    SSUserManager *userManager = [SSUserManager sharedManager];
    if (!userManager.lastSessionToken) {
        // If there is no last session token, we can't do anything (the user needs to login)
        NSLog(@"SSAlarmManager: No last session token! User needs to login.");
        errorBlock();
        return;
    }
    
    // Start a background task in case we're handling this request in the background
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // We should be finishing our work in the background well before our time is up, so if this handler gets called something went wrong
        NSLog(@"SSAlarmManager: Background task expiring!");
        errorBlock();
        [application endBackgroundTask:bgTask];
    }];
    
    if (userManager.user && userManager.currentLocation) {
        // We already have a user and current location, so go straight to changing the alarm's state
        [self changeAlarmToState:newState
                 withUserManager:userManager
                  backgroundTask:bgTask
                         success:successBlock
                           error:errorBlock];
    } else {
        // We don't have a valid user and/or current location yet, so validate the existing login first
        [self validateLoginWithUserManager:userManager
                                   success:^(SSUser *user, SSLocation *currentLocation) {
                                       // Successfully validated, proceed to change the alarm's state
                                       [self changeAlarmToState:newState
                                                withUserManager:userManager
                                                 backgroundTask:bgTask
                                                        success:successBlock
                                                          error:errorBlock];
                                   }
                                     error:errorBlock];
    }
}

+ (void)changeAlarmToState:(SSSystemState)newState
           withUserManager:(SSUserManager *)userManager
            backgroundTask:(UIBackgroundTaskIdentifier)bgTask
                   success:(void (^)())successHandler
                     error:(void (^)())errorHandler
{
    SSAPIClient *client = [SSAPIClient sharedClient];
    [client changeStateForLocation:userManager.currentLocation
                              user:userManager.user
                             state:newState
                        completion:^(SSSystemState systemState, NSError *error) {
                            if (error) {
                                NSLog(@"SSAlarmManager: Error changing alarm state.");
                                if (errorHandler) {
                                    errorHandler();
                                }
                            } else {
                                if (successHandler) {
                                    successHandler();
                                }
                            }
                            UIApplication *application = [UIApplication sharedApplication];
                            [application endBackgroundTask:bgTask];
                        }];
}

+ (void)validateLoginWithUserManager:(SSUserManager *)userManager
                             success:(void (^)(SSUser *user, SSLocation *currentLocation))successHandler
                               error:(void (^)())errorHandler
{
    if (!successHandler) {
        NSAssert(successHandler, @"Must provide a completion handler for a successful login validation.");
        return;
    }
    
    // Attempt a session validation
    [userManager validateSession:userManager.lastSessionToken withCompletion:^(SSUser *user, NSError *error) {
        // Errors happen when you can't reach the network
        if (error || !user) {
            NSLog(@"SSAlarmManager: Error validating session.");
            if (errorHandler) {
                errorHandler();
            }
            return;
        }
        
        SSAPIClient *apiClient = [SSAPIClient sharedClient];
        // No error, and we have a user. Continue on to get locations
        [apiClient fetchLocationsForUser:user completion:^(NSArray *locations, NSError *error) {
            if (error) {
                NSLog(@"SSAlarmManager: Error fetching locations.");
                if (errorHandler) {
                    errorHandler();
                }
                return;
            }
            
            // No error, so go forth
            user.locations = locations;
            userManager.user = user;
            userManager.currentLocation = user.locations.firstObject;
            
            // Execute the success handler
            successHandler(userManager.user, userManager.currentLocation);
        }];
    }];
}

@end
