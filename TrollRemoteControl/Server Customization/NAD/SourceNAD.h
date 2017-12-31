//
//  SourceNAD.h
//  DTrol
//
//  Created by Pete Maiser on 12/9/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "Source.h"

@interface SourceNAD : Source

@property (nonatomic, copy) NSString *prefix;   // Used as part of the NAD server interrogation process

@end
