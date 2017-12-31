//
//  RemoteZoneNAD.h
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteZone.h"

@interface RemoteZoneNAD : RemoteZone

// Migrate from a Model Object version "zero" of a RemoteZone to a NAD-specific RemoteZoneNAD
- (instancetype)initWithRemoteZone:(RemoteZone *)remoteZone;

@end
