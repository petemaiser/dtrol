//
//  Status.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/7/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

//  A "Status" Object enables this app to keep track of the state or status of various ~controls on the processor or receiver,
//  for example like source, volume, or tuner station.  The Status Object is a hybrid of a command feature and the last known value
//  of the particular status.  It has two exposed variable sub parts:
//     the "variable" the processor uses for this particular status item
//     the "value" is the current value from the processor
//
//  The command portion is a concatenation of the "variable" and the "commandValue" (the commandValue is set at initialization and is often a '?'),
//  literally "stringWithFormat:@"%@%@".  The current status should be maintained by a controller in the "value" property.
//  In addition, the "state" converts relevant values into 'On', 'Off', and 'not relevant' values.
//
//  Example A:
//  To keep track of a status for "Volume" where get volume you send a command like "Main.Volume?", you might initialize the command like this:
//     variable ".Volume"
//     commandValue "?"
//  and then call the command like this:  [yourCommand sendCommandToServer:yourServer withPrefix@"Main"];
//  the result should be stored into the following, and available via this Object
//     the "value" (e.g. "-35")
//

#import <Foundation/Foundation.h>
@class RemoteServer;

// Enumerated representation of the value, when applicable, for status types that have a binary
// "On" and "Off" state that drives UI switches (like Power and Mute)
typedef NS_ENUM(NSInteger, RemoteStatusState) {
    RemoteStatusStateOn = 1
    ,RemoteStatusStateOff = 0
    ,RemoteStatusStateNone = -1
};

@interface Status : NSObject <NSCopying>

@property (nonatomic, copy) NSString *variable;                 // The "variable" the processor uses for this particular status item
@property (nonatomic, copy) NSString *value;                    // The current status value

@property (nonatomic) RemoteStatusState state;                  // Enumerated representation of the value, when applicable

- (instancetype)initWithVariable:(NSString *)variable           // The "variable" the processor uses for this particular status item
                    commandValue:(NSString *)commandValue;      // The string sent to request status

// The Status Object, along with the other server interaction helper objects, will send the commands so the view controllers do not
// need to have any awareness of how a command works, they can just call it.  The Prefix abstraction enables a prefix to be added to the,
// entire command, with would typically be a reference to a zone.
- (void)sendStatusCommandToServer:(RemoteServer *)server
                 withPrefix:(NSString *)prefix;

@end
