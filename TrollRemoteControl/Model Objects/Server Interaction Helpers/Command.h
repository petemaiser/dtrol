//
//  Command.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

//  A "Command" Object is a command that can be sent to a processor or receiver.   It has two exposed variable sub parts:
//     the "variable" the processor uses for this command -- the root command itself
//     the "parameter" is the parameter value the processor will process for this command
//
//  A "parameterPrefix" can also be set at initialization that delimits the variable from the parameter (e.g. like an '=').
//  When sent a command is a straight concatenation of all three parts, literally "stringWithFormat:@"%@%@%@".  The
//  exposed parts can also be used independently if/as appropriate.
//  If there is only one "part" to a command, the "parameter" should be used.
//
//  Example A:
//  If you need a send a command that looks like this "Main.Volume=-25", you might setup the command like this:
//     variable ".Volume"
//     parameterPrefix "="
//     parameter "-25"
//  and then call the command like this:  [yourCommand sendCommandToServer:yourServer withPrefix@"Main"];
//
//  Example B:
//  If you need a send a command that looks like this "S1", you might setup the command like this:
//     variable "S"
//     parameterPrefix ""
//     parameter "1"
//  and then call the command like this:  [yourCommand sendCommandToServer:yourServer withPrefix@""];
//
//  Example C:
//  If you need a send a command that looks like this "some custom command", you might setup the command like this:
//     variable ""
//     parameterPrefix ""
//     parameter "some custom command"
//  and then call the command like this:  [yourCommand sendCommandToServer:yourServer withPrefix@""];
//
//  This object can of course be overridden if this is not enough flexibility, or if processor-specific logic is required to send the correct command

#import <Foundation/Foundation.h>
@class RemoteServer;

@interface Command : NSObject <NSCopying>

@property (nonatomic, copy) NSString *variable;                 // The "variable" the processor uses for this command / the root command itself
@property (nonatomic, copy) NSString *parameter;                // The command parameter value

- (instancetype)initWithVariable:(NSString *)variable           // The "variable" the processor uses for this command / the root command itself
              parameterPrefix:(NSString *)parameterPrefix       // The prefix the processor may expect between the root command and a parameter
                    parameter:(NSString *)parameter;            // The command parameter value

// The Command Object, along with the other server interaction helper objects, will send the commands so the view controllers do not
// need to have any awareness of how a command works, they can just call it.  The Prefix abstraction enables a prefix to be added to the,
// entire command, with would typically be a reference to a zone.
- (void)sendCommandToServer:(RemoteServer *)server
                 withPrefix:(NSString *)prefix;

@end
