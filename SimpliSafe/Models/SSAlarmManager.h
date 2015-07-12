//
//  SSAlarmManager.h
//  SimpliSafe
//
//  Created by Tyler Fox on 7/11/15.
//  Copyright (c) 2015 Tyler Fox. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSAPIClient.h"

@interface SSAlarmManager : NSObject

+ (void)automaticallySetAlarmState:(SSSystemState)newState
                           success:(void (^)(NSString *successText))successHandler
                             error:(void (^)(NSString *errorText))errorHandler;

@end
