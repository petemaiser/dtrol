//
//  RemoteTunerNAD.h
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteTuner.h"

@interface RemoteTunerNAD : RemoteTuner

@property (nonatomic) Status *bandStatus;
@property (nonatomic) Status *AMFrequencyStatus;
@property (nonatomic) Status *FMFrequencyStatus;
@property (nonatomic) Status *presetStatus;

// Migrate from a Model Object version "zero" of a RemoteTuner to a NAD-specific RemoteTunerNAD
- (instancetype)initWithRemoteTuner:(RemoteTuner *)remoteTuner;

@end
