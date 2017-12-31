//
//  ServerFinderALL.m
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "ServerFinderALL.h"
#import "ServerSetupController.h"
#import "NSString+ResponseString.h"
#import "RemoteServer.h"
#import "ServerConfigHelperAnthemAVM.h"
#import "ServerConfigHelperNAD.h"


@implementation ServerFinderALL

- (void)startServerSearch
{
    [super startServerSearch];

    // Add Model specific code here for Brand-Model Specific extensions.
    
    // Since this is just starting the server search - this is probably the first server
    // to search for in a sequence.  A "server" is a (a Brand/Model-specific command set
    // associated with particular Brand/Models of Processor/Receivers)

    
    // Step 1A - check for a NAD Type by checking for the Model (only NAD will respond to this command);
    // a successful reply will set this as a NAD Server and kick-off the interrogation.
    [self.serverSetupController.server sendString:@"Main.Model?"];
}

-(void)handleResponseString:(NSString *)string
{
    NSString *firstWord = string.first_word;
    
    if ([firstWord isEqualToString:@"Invalid"]) {
        if ([string isEqualToString:@"Invalid Command\n"])
        {
            // It is probably Anthem pre-MRX responding on Step 1A
            // Step 1B - check for Anthem pre-MRX
            self.serverSetupController.server.lineTerminationString = @"\n";
            [self.serverSetupController.server sendString:@"?"];
        }
    }
    
    // Check for a Anthem Server (pre-MRX) - response from Step 1B
    else if ( ([firstWord isEqualToString:@"AVM"]) ||
             ([firstWord isEqualToString:@"D2V"]) ||   // I don't know how exactly the Statement procs respond...making guesses
             ([firstWord isEqualToString:@"D2"]) ||
             ([firstWord isEqualToString:@"D1"]) ||
             ([firstWord isEqualToString:@"STATEMENT"]) ||
             ([firstWord isEqualToString:@"Statement"]) )
    {
        // Anthem Server FOUND
        self.serverSetupController.serverSetupStatus = ServerSetupStatusModelFound;
        self.serverSetupController.server.model = firstWord;
        [self.serverSetupController postString:[NSString stringWithFormat:@"Anthem %@ found", firstWord]
                                            to:PostStringDestinationLog|PostStringDestinationFeedback];
        
        // Turn on all the Anthem Zones
        [self.serverSetupController.server sendString:@"P1P1"];
        [self.serverSetupController.server sendString:@"P2P1"];
        [self.serverSetupController.server sendString:@"P3P1"];
        
        // Startup the Server Config Helper
        ServerConfigHelperAnthemAVM *sch = [[ServerConfigHelperAnthemAVM alloc] initWithServerSetupController:self.serverSetupController];
        self.serverSetupController.serverConfgHelper = sch;
        
        [super finishServerSearch];
    }
    
    // Check for a NAD Server - response from Step 1A
    else
    {
        // Use custom categories from NSString+NADResponseString
        NSString *prefix = string.nad_prefix;
        NSString *variable = string.nad_variable;
        NSString *value = string.nad_value;
        
        if (prefix && variable && value) {
            if ([variable isEqualToString:@"Model"]) {
                
                // NAD Server FOUND
                self.serverSetupController.serverSetupStatus = ServerSetupStatusModelFound;
                self.serverSetupController.server.model = value;
                [self.serverSetupController postString:[NSString stringWithFormat:@"NAD %@ found", value]
                                                    to:PostStringDestinationLog|PostStringDestinationFeedback];
                
                // Startup the Server Config Helper
                ServerConfigHelperNAD *sch = [[ServerConfigHelperNAD alloc] initWithServerSetupController:self.serverSetupController];
                self.serverSetupController.serverConfgHelper = sch;
                
                [super finishServerSearch];
                
            }
        }
    }
}

@end
