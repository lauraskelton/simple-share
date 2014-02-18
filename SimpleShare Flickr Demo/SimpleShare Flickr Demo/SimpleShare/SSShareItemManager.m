//
//  SSShareItemManager.m
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "SSShareItemManager.h"
#import "SimpleShare.h"

@interface SSShareItemManager ()
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *appCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (nonatomic, assign) BOOL                      isBluetoothReady;


- (BOOL)isLECapableHardware;
@end



#define NOTIFY_MTU      20

@implementation SSShareItemManager

@synthesize isReadyToAdvertise, delegate, myItemIDs;

- (id)init {
	if ((self = [super init])) {
        
        // Start up the CBPeripheralManager
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
	}
	return self;
}

#pragma mark - Peripheral Methods

// Use CBPeripheralManager to check whether the current platform/hardware supports Bluetooth LE.
- (BOOL)isLECapableHardware
{
    NSString * state = nil;
    switch ([self.peripheralManager state]) {
        case CBPeripheralManagerStateUnsupported:
            state = @"Your hardware doesn't support Bluetooth LE sharing.";
            break;
        case CBPeripheralManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth. You can change this in the Settings app.";
            break;
        case CBPeripheralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBPeripheralManagerStateResetting:
            state = @"Bluetooth is currently resetting.";
            break;
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"powered on");
            return TRUE;
        case CBPeripheralManagerStateUnknown:
            NSLog(@"state unknown");
            return FALSE;
        default:
            return FALSE;
            
    }
    NSLog(@"Peripheral manager state: %@", state);
    [self stopAdvertisingItems:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate shareItemManagerDidFailWithMessage:state];
    });
    
    return FALSE;

}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
    if ([self isLECapableHardware] != YES) {
        NSLog(@"not capable");
        self.isReadyToAdvertise = NO;
        if ([peripheral state] == CBPeripheralManagerStateUnknown) {
            NSLog(@"bluetooth peripheral state unknown 2");
        } else {
            // should we stop sharing items now?
            NSLog(@"end advertise items");
            [self stopAdvertisingItems:nil];
        }
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    self.isReadyToAdvertise = YES;
    
    // ... so build our service.
    
    self.appCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]
                                                                properties:CBCharacteristicPropertyNotify
                                                                     value:nil
                                                               permissions:CBAttributePermissionsReadable];
    
    // Then the service
    CBMutableService *appService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]
                                                                  primary:YES];
    
    
    // Add the characteristic to the service
    appService.characteristics = @[self.appCharacteristic];
    
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:appService];
    
    [self startAdvertisingItems:nil];
    
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    if (self.myItemIDs == nil || [self.myItemIDs count] < 1) {
        NSLog(@"Error: no item IDs to share.");
    } else {
        
        // Get the data
        self.dataToSend = [[self.myItemIDs componentsJoinedByString:@","] dataUsingEncoding:NSUTF8StringEncoding];
        
        // Reset the index
        self.sendDataIndex = 0;
        
        // Start sending
        [self sendData];
    }
    
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}

/** Sends the next amount of data to the connected central
 */
- (void)sendDataIndicate
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        NSLog(@"no data left");
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            NSLog(@"not did send retry");
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent retry: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
    
}


/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        NSLog(@"no data left");
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            NSLog(@"not did send first");
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent first: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.appCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
    
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    [self sendDataIndicate];
    
}

#pragma mark - Advertisements

- (void)startAdvertisingItems:(id)sender
{
    
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:[SimpleShare sharedInstance].simpleShareAppID]];
    
    NSDictionary *advertisingDictionary =
    [NSDictionary
     dictionaryWithObjectsAndKeys:services, CBAdvertisementDataServiceUUIDsKey,
     @"SimpleShareService", CBAdvertisementDataLocalNameKey,
     nil];
    
    [self.peripheralManager startAdvertising:advertisingDictionary];
    
    NSLog(@"advertisement: %@", advertisingDictionary);

}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error)
    {
        NSLog(@"error starting advertising: %@", error);
        return;
    }
    
    NSLog(@"peripheral manager did start advertising: %d", peripheral.isAdvertising);
}

-(BOOL)isPeripheralAdvertising:(id)sender
{
    NSLog(@"peripheral is advertising: %d", self.peripheralManager.isAdvertising);
    return self.peripheralManager.isAdvertising;
}

- (void)stopAdvertisingItems:(id)sender
{
    [self.peripheralManager stopAdvertising];
    NSLog(@"peripheral manager did stop advertising");
}


@end
