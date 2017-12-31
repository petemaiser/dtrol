//
//  ServerFinder.h
//  DTrol
//
//  Created by Pete Maiser on 11/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>
@class ServerSetupController;

@interface ServerFinder : NSObject

@property (weak, nonatomic) ServerSetupController *serverSetupController;
@property (nonatomic, copy) void (^feedbackBlock)(NSString *);

- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc;
- (void)startServerSearch;
- (void)finishServerSearch;
- (void)abortServerSearch;

@end
