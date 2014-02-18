//
//  SimpleShare.m
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "SimpleShare.h"

#define kSSAskedBluetoothPermissionKey @"ss_askedbluetoothpermission_key"

@implementation SimpleShare

@synthesize shareManager = _shareManager, findManager = _findManager, simpleShareAppID = _simpleShareAppID, myItemIDs = _myItemIDs, foundItemIDs = _foundItemIDs, bluetoothPermissionExplanation, delegate;

+ (SimpleShare *)sharedInstance
{
    static SimpleShare *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SimpleShare alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // default bluetooth permissions explanation - you can set this to a custom explanation
    // e.g. [SimpleShare sharedInstance].bluetoothPermissionExplanation = @"We use bluetooth to share your groups nearby.";
    
    self.bluetoothPermissionExplanation = @"This app uses Bluetooth to find and share items nearby.";
    
    return self;
}

-(void)dealloc
{
    _simpleShareAppID = nil;
    _shareManager = nil;
    _findManager = nil;
}

-(void)setMyItemIDs:(NSMutableArray *)newMyItemIDs
{
    if (_myItemIDs != newMyItemIDs) {
        _myItemIDs = newMyItemIDs;
        
        if (_shareManager != nil) {
            // Update the share item manager.
            _shareManager.myItemIDs = _myItemIDs;
        }
        
        if (_findManager != nil) {
            // Update the find item manager.
            _findManager.myItemIDs = _myItemIDs;
        }
    }
}

-(void)shareMyItems:(id)sender
{
    // First check if we've asked permission for bluetooth before
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSSAskedBluetoothPermissionKey] != YES) {
        // we haven't asked bluetooth permission before, so show alertview asking for it
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSSAskedBluetoothPermissionKey];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share with Bluetooth" message:self.bluetoothPermissionExplanation delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = 1;
        [alert show];
        return;
    } else {
        _shareManager = [[SSShareItemManager alloc] init];
        _shareManager.delegate = self;
        _shareManager.myItemIDs = _myItemIDs;
    }
}

-(void)stopSharingMyItems:(id)sender
{
    if (_shareManager != nil) {
        [_shareManager stopAdvertisingItems:nil];
        _shareManager = nil;
    }
}

-(void)findNearbyItems:(id)sender
{
    [self stopFindingNearbyItems:nil];
        
    // First check if we've asked permission for bluetooth before
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSSAskedBluetoothPermissionKey] != YES) {
        // we haven't asked bluetooth permission before, so show alertview asking for it
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSSAskedBluetoothPermissionKey];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Find with Bluetooth" message:self.bluetoothPermissionExplanation delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = 2;
        [alert show];
        return;
    } else {
        _findManager = [[SSFindItemManager alloc] init];
        _findManager.delegate = self;
        _findManager.myItemIDs = _myItemIDs;
    }
}

-(void)stopFindingNearbyItems:(id)sender
{
    if (_findManager != nil) {
        [_findManager endFindItem:nil];
        _findManager = nil;
        _foundItemIDs = nil;
    }
}

#pragma mark - Find Item Manager Delegate

- (void)findItemManagerFoundItemIDs:(NSArray *)itemIDs
{
    if (_foundItemIDs == nil) {
        _foundItemIDs = [[NSMutableArray alloc] init];
        [_foundItemIDs addObjectsFromArray:itemIDs];
        [delegate simpleShareFoundFirstItems:itemIDs];
        return;
    }
    
    NSMutableArray *moreItemIDsArray = [[NSMutableArray alloc] init];
    for (NSString *anItemID in itemIDs) {
        if ([_foundItemIDs containsObject:anItemID] == NO) {
            [_foundItemIDs addObject:anItemID];
            [moreItemIDsArray addObject:anItemID];
        }
    }
    [delegate simpleShareFoundMoreItems:moreItemIDsArray];
    moreItemIDsArray = nil;

}

- (void)findItemManagerFoundNoItems:(SSFindItemManager *)findItemManager
{
    [findItemManager endFindItem:nil];
    _findManager = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing Found" message:@"Couldn't find anything new nearby right now." delegate:nil cancelButtonTitle:nil otherButtonTitles: @"OK", nil];
    [alert show];
    
    [delegate simpleShareFoundNoItems:self];
}

- (void)findItemManagerDidFailWithMessage:(NSString *)failMessage
{
    // No bluetooth connection
    
    _findManager = nil;
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Bluetooth Support", nil) message:failMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
    
    [delegate simpleShareDidFailWithMessage:failMessage];
}

#pragma mark - Share Item Manager Delegate

- (void)shareItemManagerDidFailWithMessage:(NSString *)failMessage
{
    // No bluetooth connection
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Bluetooth Support", nil) message:failMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
    
    [delegate simpleShareDidFailWithMessage:failMessage];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        // share items bluetooth permission alert- start sharing items
        _shareManager = [[SSShareItemManager alloc] init];
        _shareManager.delegate = self;
        _shareManager.myItemIDs = _myItemIDs;
    }
    else if (alertView.tag == 2) {
        // find items bluetooth permission alert- start finding items
        _findManager = [[SSFindItemManager alloc] init];
        _findManager.delegate = self;
        _findManager.myItemIDs = _myItemIDs;
    }
}

@end
