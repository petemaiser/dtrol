//
//  Source.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

//  A source represents a source on the processor or receiver; it is a wrapper to a Command to switch to that source.
//  As a wrapper it includes a display name for the source, provides the value for this particular source, and
//  determines if the source is enabled or not in this app

#import <Foundation/Foundation.h>
@class Command;
@class RemoteServer;

@interface Source : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy) NSString *name;             // The display name of this particular source
@property (nonatomic, copy) NSString *value;            // The "value" the processor uses for this particular source when reporting status
@property (nonatomic, copy) NSString *enabled;          // Indicates if this particular source is enabled or not within this app

- (instancetype)initWithName:(NSString *)name           // The display name of this particular source
                    variable:(NSString *)variable       // The "variable" the processor uses for source commands and status
                       value:(NSString *)value          // The "value" the processor uses for this particular source when reporting status
               sourceCommand:(Command *)command         // A Command Object to hold the command to switch to this particular source
                     enabled:(NSString *)enabled;       // Indicates if this particular source is enabled or not within this app

// The Source Object, along with the other server interaction helper objects, will send the commands so the view controllers do not
// need to have any awareness of how a source-command works, they can just call it.  The Prefix abstraction enables a prefix to be added to the,
// entire command, with would typically be a reference to a zone.
- (void)sendSourceCommandToServer:(RemoteServer *)server
                       withPrefix:(NSString *)prefix;

- (void) encodeWithCoder:( NSCoder *) aCoder;
- (instancetype) initWithCoder:( NSCoder *) aDecoder;

@end
