//
//  SimpleShare.h
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSShareItemManager.h"
#import "SSFindItemManager.h"

@class SimpleShare;

@protocol SimpleShareDelegate <NSObject>
- (void)simpleShareFoundFirstItems:(NSArray *)itemIDs;
- (void)simpleShareFoundMoreItems:(NSArray *)itemIDs;
- (void)simpleShareFoundNoItems:(SimpleShare *)simpleShare;
- (void)simpleShareDidFailWithMessage:(NSString *)failMessage;
@end

@interface SimpleShare : NSObject <SSShareItemManagerDelegate, SSFindItemManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) id <SimpleShareDelegate> delegate;
@property (nonatomic, retain) SSShareItemManager *shareManager;
@property (nonatomic, retain) SSFindItemManager *findManager;
@property (nonatomic, retain) NSString *simpleShareAppID;
@property (nonatomic, retain) NSMutableArray *myItemIDs;
@property (nonatomic, retain) NSMutableArray *foundItemIDs;
@property (nonatomic, retain) NSString *bluetoothPermissionExplanation;

+ (SimpleShare *)sharedInstance;

-(void)shareMyItems:(id)sender;
-(void)stopSharingMyItems:(id)sender;
-(void)findNearbyItems:(id)sender;
-(void)stopFindingNearbyItems:(id)sender;

@end
