//
//  NSString+NADResponseString.m
//
//  Created by Pete Maiser on 2/23/17.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "NSString+ResponseString.h"

@implementation NSString (ResponseString)

- (NSString *)first_word
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@" "];
    
    if ([components count] > 1) {
        s = components[0];
    }
    return s;
}

- (NSString *)second_word
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@" "];
    
    if ([components count] > 1) {
        s = components[1];
    }
    return s;
}

- (NSString *)nad_prefix
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@"."];
    
    if ([components count] > 1) {
        s = components[0];
    }
    return s;
}

- (NSString *)nad_variable
{
    
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [components1[0] componentsSeparatedByString:@"."];
        if ([components2 count] == 2) {
            s = components2[1];
        } else if ([components2 count] == 3) {
            s = [NSString stringWithFormat:@"%@.%@", components2[1], components2[2]];
        }
    }
    return s;
}

- (NSString *)nad_variable1
{
    
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [components1[0] componentsSeparatedByString:@"."];
        if ([components2 count] >= 2) {
            s = components2[1];
        }
    }
    return s;
}

- (NSString *)nad_variable2
{
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [components1[0] componentsSeparatedByString:@"."];
        if ([components2 count] == 3) {
            s = components2[2];
        }
    }
    return s;
}

- (NSString *)nad_value
{
    NSString *s = nil;
    NSArray *responseStringComponents = [self componentsSeparatedByString:@"="];
    
    if ([responseStringComponents count] > 1) {
        s = responseStringComponents[1];
    }
    return s;
}

@end
