//
//  TunerStationAnthemAVM.m
//  DTrol
//
//  Created by Pete Maiser on 11/21/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "TunerStationAnthemAVM.h"
#import "RemoteServer.h"
#import "NSString+ResponseString.h"

@implementation TunerStationAnthemAVM

- (instancetype)initWithFrequencyText:(NSString *)freqencyText
{
    self = [super init];
    
    // Set values
    if (self ) {
        self.frequencyText = freqencyText;
    }
    return self;
}

- (void)sendStationCommandToServer:(RemoteServer *)server
{
    // Separate the frequency text into the "number" and the band value.
    // This whole thing is a bit suspect but seeking to keep this local tuner stuff quick and simple to program / it will be rarely used
    
    NSString *frequencyNumberText = self.frequencyText.first_word;
    NSString *freqenceyBandText = self.frequencyText.second_word;
    
    NSString *stationCommandString = nil;
    if ([freqenceyBandText hasPrefix:@"F"]) {
        stationCommandString = [NSString stringWithFormat:@"TFT%@",frequencyNumberText];
    } else if ([freqenceyBandText hasPrefix:@"A"]) {
        stationCommandString = [NSString stringWithFormat:@"TAT%@",frequencyNumberText];
    }
    [server sendString:stationCommandString];
}

@end
