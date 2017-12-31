//
//  NSString+NADResponseString.h
//
//  Created by Pete Maiser on 2/23/17.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>

@interface NSString (ResponseString) // Category on NSString to enable easy processing of response strings 

// word processing
- (NSString *)first_word;
- (NSString *)second_word;

// for NAD devices that reply with ZONE.VAR.OPTIONALVAR=VALUE
- (NSString *)nad_prefix;
- (NSString *)nad_variable;     // Total Variable - i.e. everything between the first dot and the equal sign
- (NSString *)nad_variable1;    // First Variable - i.e. everything between the first dot and the second dot
- (NSString *)nad_variable2;    // Second Variable, if applicable - i.e. everything between the second dot and the equal sign
- (NSString *)nad_value;

@end
