//
//  RemoteTunerAnthemAVM.h
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteTuner.h"

@interface RemoteTunerAnthemAVM: RemoteTuner

@property (nonatomic) Status *frequencyStatus;
@property (nonatomic) NSInteger presetIndex;        // Use -1 for preset not used or not set

- (void) sendRequestForStatusAthemAVMTuner;

@end
