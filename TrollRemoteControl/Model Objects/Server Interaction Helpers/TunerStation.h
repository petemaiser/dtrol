//
//  TunerStation.h
//  DTrol
//
//  Created by Pete Maiser on 11/21/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

//  This class exists to enable "Local" type tuner preset control where we will build "Tuner Station" present capability
//  into this app.  The reason this craziness exists is for Anthem AVM style tuner control where preset seek is not supported.
//  This occurs on pre-MRX Anthem components, i.e. AVM less than "60" plus D1 and D2 variants.

#import <Foundation/Foundation.h>
@class RemoteServer;

@interface TunerStation : NSObject <NSSecureCoding>

@property (nonatomic) NSString *frequencyText;

- (void)sendStationCommandToServer:(RemoteServer *)server;

@end
