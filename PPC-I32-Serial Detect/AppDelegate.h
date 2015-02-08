//
//  AppDelegate.h
//
//  Mac OS X PL2303 / CH340 / CH340 USB to Serial Detect
//  For drivers, please visit: https://www.mac-usb-serial.com
//
//  Created by Jeroen Arnoldus on 07-02-15.
//  Copyright (c) 2015 Repleo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject {
	NSWindow							*window;
	NSTableView							*deviceTable;
	NSButton							*obtainButton;
	NSTextField							*detailLabel;

    NSMutableArray                      *deviceArray;
    io_iterator_t                       gNewDeviceAddedIter;
    io_iterator_t                       gNewDeviceRemovedIter;
    IONotificationPortRef               gNotifyPort;
    CFMutableDictionaryRef              classToMatch;
}

@property (assign) IBOutlet NSWindow    *window;
@property (assign) IBOutlet NSTableView *deviceTable;
@property (assign) IBOutlet NSButton    *obtainButton;
@property (assign) IBOutlet NSTextField *detailLabel;



- (void) deviceAdded: (io_iterator_t) iterator;
- (void) deviceRemoved: (io_iterator_t) iterator;

-(NSString *) getDeviceChip:(NSNumber *)idVendor idProduct:(NSNumber *)idProduct;
-(NSMutableArray *) getDevicePersonalities: (NSString *)device;


- (IBAction)visitWebsite:(id)sender;
- (IBAction)obtainDriver:(id)sender;

@end

