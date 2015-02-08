//
//  AppDelegate.m
//
//  Mac OS X PL2303 / CH340 / CH340 USB to Serial Detect
//  For drivers, please visit: https://www.mac-usb-serial.com
//
//  Created by Jeroen Arnoldus on 07-02-15.
//  Copyright (c) 2015 Repleo. All rights reserved.
//

#import "AppDelegate.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IODataQueueShared.h>
#include <IOKit/IODataQueueClient.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#include <pthread.h>
#include <mach/mach_port.h>

#import <CoreFoundation/CFMachPort.h>
#import <CoreFoundation/CFNumber.h>
#import <CoreFoundation/CoreFoundation.h>

__BEGIN_DECLS
#include <mach/mach.h>
#include <IOKit/iokitmig.h>
__END_DECLS


#import "Model.h"


#include <IOKit/IOKitLib.h>

@implementation AppDelegate

@synthesize window;
@synthesize deviceTable;
@synthesize obtainButton;
@synthesize detailLabel;

#pragma mark ######### static wrappers #########

static void staticDeviceAdded (void *refCon, io_iterator_t iterator){
    AppDelegate *del = refCon;
    if (del)
        [del deviceAdded : iterator];
}

static void staticDeviceRemoved (void *refCon, io_iterator_t iterator){
    AppDelegate *del = refCon;
    if (del)
        [del deviceRemoved : iterator];
}

#pragma mark ######### hotplug callbacks #########

- (void) deviceAdded: (io_iterator_t) iterator{
    io_service_t		serviceObject;
    IOCFPlugInInterface	**plugInInterface = NULL;
    IOUSBDeviceInterface	**dev = NULL;
    SInt32			score;
    kern_return_t		kr;
    HRESULT			result;
    CFMutableDictionaryRef	entryProperties = NULL;
    
    while ((serviceObject = IOIteratorNext(iterator))) {
        //printf("%s(): device added %d.\n", __func__, (int) serviceObject);
        IORegistryEntryCreateCFProperties(serviceObject, &entryProperties, NULL, 0);
        
        kr = IOCreatePlugInInterfaceForService(serviceObject,
                                               kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        
        if ((kr != kIOReturnSuccess) || !plugInInterface) {
            printf("%s(): Unable to create a plug-in (%08x)\n", __func__, kr);
            continue;
        }
        
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                    (LPVOID *)&dev);
        
        (*plugInInterface)->Release(plugInInterface);
        
        if (result || !dev) {
            printf("%s(): Couldn’t create a device interface (%08x)\n", __func__, (int) result);
            continue;
        }
        
        
        UInt16 vendorID, productID;
        (*dev)->GetDeviceVendor(dev, &vendorID);
        (*dev)->GetDeviceProduct(dev, &productID);
        NSString *name = (NSString *) CFDictionaryGetValue(entryProperties, CFSTR("USB Product Name"));
        if (!name)
            continue;
        
        NSNumber *idVendor = [NSNumber numberWithInteger:vendorID];
        NSNumber *idProduct = [NSNumber numberWithInteger:productID];
        NSString *chip = [self getDeviceChip:idVendor idProduct:idProduct];
        if (chip) {
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity: 0];
            
            [dict setObject: [NSString stringWithFormat: @"0x%04x", vendorID]
                     forKey: @"VID"];
            [dict setObject: [NSString stringWithFormat: @"0x%04x", productID]
                     forKey: @"PID"];
            [dict setObject: [NSString stringWithString: name]
                     forKey: @"name"];
            [dict setObject: [NSValue valueWithPointer: dev]
                     forKey: @"dev"];
            [dict setObject: [NSNumber numberWithInt: serviceObject]
                     forKey: @"service"];
            [dict setObject: [NSString stringWithString:chip]
                     forKey: @"chip"];
            [deviceArray addObject: dict];
        }
        
    }
    
    [deviceTable reloadData];
}

- (void) deviceRemoved: (io_iterator_t) iterator{
    io_service_t serviceObject;
    
    while ((serviceObject = IOIteratorNext(iterator))) {
        NSEnumerator *enumerator = [deviceArray objectEnumerator];
        NSDictionary *dict;
        
        while (dict = [enumerator nextObject]) {
            if ((io_service_t) [[dict valueForKey: @"service"] intValue] == serviceObject) {
                [deviceArray removeObject: dict];
                break;
            }
        }
        
        IOObjectRelease(serviceObject);
    }
    
    [deviceTable reloadData];
}

#pragma mark ############ The Logic #############

- (void) listenForDevices{
    OSStatus ret;
    CFRunLoopSourceRef runLoopSource;
    mach_port_t masterPort;
    kern_return_t kernResult;
    
    deviceArray = [[NSMutableArray alloc] initWithCapacity: 0];
    
    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    if (kernResult != kIOReturnSuccess) {
        printf("%s(): IOMasterPort() returned %08x\n", __func__, kernResult);
        return;
    }
    
    classToMatch = IOServiceMatching(kIOUSBDeviceClassName);
    if (!classToMatch) {
        printf("%s(): IOServiceMatching returned a NULL dictionary.\n", __func__);
        return;
    }
    
    CFRetain(classToMatch);
    
    gNotifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    
    ret = IOServiceAddMatchingNotification(gNotifyPort,
                                           kIOFirstMatchNotification,
                                           classToMatch,
                                           staticDeviceAdded,
                                           self,
                                           &gNewDeviceAddedIter);
    
    [self deviceAdded: gNewDeviceAddedIter];
    ret = IOServiceAddMatchingNotification(gNotifyPort,
                                           kIOTerminatedNotification,
                                           classToMatch,
                                           staticDeviceRemoved,
                                           self,
                                           &gNewDeviceRemovedIter);
    
    [self deviceRemoved : gNewDeviceRemovedIter];
    mach_port_deallocate(mach_task_self(), masterPort);
}


-(NSMutableArray *) getDevicePersonalities: (NSString *)device{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/Contents/Resources/%@.plist", device]];
    NSMutableDictionary* plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:finalPath];
    NSMutableDictionary *driver_personalities =  [plistDictionary objectForKey:@"IOKitPersonalities"];
    NSMutableArray *result=[[NSMutableArray alloc] init];
    for(id personality_key in driver_personalities){
        NSMutableDictionary* personality = [driver_personalities objectForKey:personality_key];
        NSNumber *idVendor = [personality objectForKey:@"idVendor"];
        NSNumber *idProduct = [personality objectForKey:@"idProduct"];
        Personality *pers = [[Personality alloc]initWithPersonality:idVendor idProduct:idProduct];
        
        [result addObject:pers];
    }
    return result;
}

-(NSString *) getDeviceChip:(NSNumber *)idVendor idProduct:(NSNumber *)idProduct{
    Personality *pers = [[Personality alloc]initWithPersonality:idVendor idProduct:idProduct];
    NSMutableArray *ch341_personalities = [self getDevicePersonalities:@"ch341"];
    for(Personality *personality in ch341_personalities){

        if ([personality isEqual:pers]) {
            return @"ch341";
        }
    }
    NSMutableArray *pl2303_personalities = [self getDevicePersonalities:@"pl2303"];
    for(Personality *personality in pl2303_personalities){
        if ([personality isEqual:pers]) {
            return @"pl2303";
        }
    }
    return nil;
}

#pragma mark ######### table view data source protocol ############

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:obj
   forTableColumn:(NSTableColumn *)col
              row:(NSInteger)rowIndex{
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)col
            row:(NSInteger)rowIndex{
    NSDictionary *dict = [deviceArray objectAtIndex: rowIndex];
    return [dict valueForKey: [col identifier]];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView{
    if ([deviceArray count] > 0 ){
        [obtainButton setEnabled:YES];
        if ([deviceArray count] > 1 ){
            [detailLabel setStringValue:@"We found multiple compatible USB to Serial devices.\n\nTo download the suitable driver, please press the button below."];
        } else {
            [detailLabel setStringValue:@"We found a compatible USB to Serial device.\n\nTo download the suitable driver, please press the button below."];
        }
    } else {
        [obtainButton setEnabled:NO];
        
        [detailLabel setStringValue:@"Please connect a USB to Serial device to your Mac. If the cable is supported, it will be listed in the table.\n\nIf you own a PL2303 or CH340 compatible device and is it not listed, please contact: support@mac-usb-serial.com"];

    }
    return [deviceArray count];
}

#pragma mark ############ Button actions #############

- (IBAction)visitWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.mac-usb-serial.com/"]];
    
    
}

- (IBAction)obtainDriver:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.mac-usb-serial.com/"]];

    
}

#pragma mark ############ NSApplication delegate protocol #############

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Hello World");
    [self listenForDevices];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    
    [window makeKeyAndOrderFront:self];
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

    // Insert code here to tear down your application
}

@end


