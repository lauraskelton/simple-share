//
//  SSFindItemManager.m
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "SSFindItemManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SimpleShare.h"

@interface SSFindItemManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;

@end

@implementation SSFindItemManager
@synthesize delegate, myItemIDs = _myItemIDs;

- (id)init {
	if ((self = [super init])) {
        
        // Start up the CBCentralManager
        dispatch_queue_t centralQueue = dispatch_queue_create("com.simpleshare.mycentral", DISPATCH_QUEUE_SERIAL);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
        
        // And somewhere to store the incoming data
        _data = [[NSMutableData alloc] init];
        
        _foundOneItem = NO;
        
	}
	return self;
}

-(void)findItemManagerWillStop:(id)sender
{
    // Don't keep it going while we're not showing.
    NSLog(@"Scanning stopped");
    [self cleanup];
    [self.centralManager stopScan];
    
}

#pragma mark - Central Methods

// Use CBCentralManager to check whether the current platform/hardware supports Bluetooth LE.
- (BOOL)isLECapableHardware
{

    NSString * state = nil;
    switch ([self.centralManager state]) {
        case CBCentralManagerStateUnsupported:
            state = @"Your hardware doesn't support Bluetooth LE sharing.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth. You can change this in the Settings app.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStateResetting:
            state = @"Bluetooth is currently resetting.";
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"powered on");
            return TRUE;
        case CBCentralManagerStateUnknown:
            NSLog(@"state unknown");
            return FALSE;
        default:
            return FALSE;
            
    }
    NSLog(@"Central manager state: %@", state);
    [self endFindItem:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate findItemManagerDidFailWithMessage:state];
    });
    
    return FALSE;
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([self isLECapableHardware] != YES) {
        NSLog(@"not capable");
        return;
    }
    NSLog(@"capable");
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    
    if (_foundPeripherals != nil) {
        NSLog(@"foundPeripherals != nil");
        if ([_foundPeripherals count] > 0) {
            [_foundPeripherals removeAllObjects];
        }
        _foundPeripherals = nil;
    }
    
    _foundPeripherals = [[NSMutableArray alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(noLocalItems:) withObject:nil afterDelay:15.0];
    });
    
    [self scan];
    
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    
    
    NSLog(@"Scanning started");
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@ %@ at %@", peripheral.name, peripheral.identifier, RSSI);
        
        if ([_foundPeripherals containsObject:peripheral.identifier] == NO) {
            
            NSLog(@"we haven't connected before");
            
            //NSLog(@"Discovered %@ %@ at %@", peripheral.name, peripheral.identifier, RSSI);
            
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            self.discoveredPeripheral = peripheral;
            
            // Stop scanning
            [self.centralManager stopScan];
            NSLog(@"Scanning stopped");

            // And connect
            NSLog(@"Connecting to peripheral %@", peripheral);
            [_foundPeripherals addObject:peripheral.identifier];
            [self.centralManager connectPeripheral:peripheral options:nil];

        }
    
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Clear the data that we may already have
    [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]]];
}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]] forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        
        // We have, so show the data,
        NSLog(@"complete received message: %@", [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]);
        //[self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        NSArray *itemIDsArray = [[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
        
        
        NSMutableArray *newItemIDsArray = [[NSMutableArray alloc] init];
        for (NSString *anItemID in itemIDsArray) {
            
            // do we already have this item?
            if ([_myItemIDs containsObject:anItemID] == NO) {

                [newItemIDsArray addObject:anItemID];
            }
        }
        if ([newItemIDsArray count] > 0) {
            [self addItemIDsToList:newItemIDsArray];
        }
        newItemIDsArray = nil;
        
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.discoveredPeripheral.isConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

#pragma mark - custom methods

-(void)noLocalItems:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate findItemManagerFoundNoItems:self];
    });
}

-(void)addItemIDsToList:(NSArray *)itemIDs
{
    NSLog(@"found item IDs: %@", itemIDs);
    
        // if an item is found, call this to cancel no items found alert:
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(noLocalItems:) object:nil];
        });
        
        // tell the delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate findItemManagerFoundItemIDs:itemIDs];
        });
    
}

-(void)endFindItem:(id)sender
{
    [self findItemManagerWillStop:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(noLocalItems:) object:nil];
    });
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.centralManager stopScan];
    [self cleanup];
    
    self.discoveredPeripheral = nil;
    self.data = nil;
    
    self.centralManager.delegate = nil;
    self.centralManager = nil;
    
}

@end
