//
//  SSFindItemManager.h
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SSFindItemManager;


@protocol SSFindItemManagerDelegate <NSObject>
- (void)findItemManagerFoundItemIDs:(NSArray *)itemIDs;
- (void)findItemManagerFoundNoItems:(SSFindItemManager *)findItemManager;
- (void)findItemManagerDidFailWithMessage:(NSString *)failMessage;
@end

@interface SSFindItemManager : NSObject
{
    NSMutableArray *_foundPeripherals;
    BOOL _foundOneItem;
}

@property (nonatomic, assign) id <SSFindItemManagerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *myItemIDs;

-(void)noLocalItems:(id)sender;
-(void)addItemIDsToList:(NSArray *)itemIDs;
-(void)endFindItem:(id)sender;

-(void)findItemManagerWillStop:(id)sender;

@end
