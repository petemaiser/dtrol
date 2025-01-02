//
//  UserPreferences.h
//  DTrol
//
//  Created by Pete Maiser on 1/4/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserPreferences : NSObject <NSSecureCoding>

@property BOOL showZoneSetupButtons;
@property BOOL enableAutoPowerOnTuner;
@property BOOL enableAutoPowerOnApps;
@property (readonly) NSTimeInterval timeout;    // Readonly for now...at some point make this a real setting

- (instancetype)init;

@end
