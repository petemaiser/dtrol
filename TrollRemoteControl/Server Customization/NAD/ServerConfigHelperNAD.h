//
//  ServerConfigHelperNAD.h
//
//  Created by Pete Maiser on 2/26/17.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "ServerConfigHelper.h"
@class RemoteTunerNAD;

@interface ServerConfigHelperNAD : ServerConfigHelper

- (void)configureTunerNAD:(RemoteTunerNAD *)tuner;

@end
