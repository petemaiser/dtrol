//
//  Log.m
//  GameCalc, TrollRemoteControl
//
//  Created by Pete Maiser on 3/25/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "Log.h"
#import "LogItem.h"

@interface Log ()
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSMutableArray *privateLogItems;
@end

@implementation Log

+ (instancetype)sharedLog
{
    // As a singleton, make the pointer to the store static so that it will always exist
    static Log *sharedLog;
    
    // Check if the shared store already exists; if not create it
    if (!sharedLog) {
        sharedLog = [[self alloc] initPrivate];
    }
    return sharedLog;
    
}

- (instancetype)init
{
    // This method should not be used
    [NSException raise:@"Singleton" format:@"Use +[Log sharedLog]"];
    return nil;
}

- (instancetype)initPrivate
{
    // This is the real initializer
    self = [super init];
    if (self) {
        
        // Configure helpers
        if (self.numberFormatter == nil) {
            self.numberFormatter = [[NSNumberFormatter alloc] init];
            [self.numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
            [self.numberFormatter setMaximumFractionDigits:0];
        }
        
        // First try to retrieve saved items
        NSError *error;
        NSData *data = [[NSData alloc] initWithContentsOfFile:[self archivePath]];
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[LogItem class]
                                                ,[NSString class]
                                                ,nil];
        _privateLogItems = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        
        // If there are no saved items then start fresh
        if (!_privateLogItems) {
            _privateLogItems = [[NSMutableArray alloc] init];
            
            [self addDivider];
            
            LogItem *logTextTopLine1 = [LogItem logItemWithText:[NSString stringWithFormat:@"DTrol controls your"] ];
            [_privateLogItems addObject:logTextTopLine1];
            LogItem *logTextTopLine2 = [LogItem logItemWithText:[NSString stringWithFormat:@"processors and receivers!"] ];
            [_privateLogItems addObject:logTextTopLine2];
           
            [self addDivider];

            LogItem *logTextTopLine3 = [LogItem logItemWithText:[NSString stringWithFormat:@"Touch the '+' to add a Server."] ];
            [_privateLogItems addObject:logTextTopLine3];
            
        }
        
    }
    return self;
}


- (NSArray *)logItems
{
    //Override the getter of all* to return a copy of private *
    return [self.privateLogItems copy];
}

- (void)addItem:(LogItem *)logItem
{
    if (logItem) {
        [self.privateLogItems addObject:logItem];
    }
}

- (void)trimTopItems:(long int)trimCount
{
    NSRange trimRange = NSMakeRange(0, trimCount);
    [self.privateLogItems removeObjectsInRange:trimRange];

    LogItem *logTextLine = [LogItem logItemWithText:[NSString stringWithFormat:@"%s:  oldest %ld lines deleted from log to reduce log size."
                                                     ,getprogname()
                                                     ,trimCount]];
    [self addItem:logTextLine];
}

- (void)addDivider
{
    LogItem *logTextDivder = [LogItem logItemWithText:[NSString stringWithFormat:@"----------------------------------------"]];
    [self addItem:logTextDivder];
}

- (BOOL)saveLog
{
    // Check if the log is too big, and if so trip some top lines
    long int logItemsCount = [self.privateLogItems count];
    if (logItemsCount > maxItems) {
        [self trimTopItems:(logItemsCount - maxItems)];
    }
    
    // Archive
    NSError *error;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self.privateLogItems requiringSecureCoding:YES error:&error];
    return [data writeToFile:[self archivePath] atomically:YES];
}

- (NSString *)archivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    NSString *archiveFile = [NSString stringWithFormat:@"%@.log.archive", [NSString stringWithUTF8String:getprogname()]];
    
    NSString *archivePath = [documentDirectory stringByAppendingPathComponent:archiveFile];
    
    return archivePath;
}


@end
