Description
===========
Easy Proximity-based Sharing for iOS

Perfect for any iOS app that needs to quickly share items with nearby friends, such as groups, photo albums, photos, links, user profiles, etc, using Bluetooth Low Energy.

Users simply click "find nearby", and items from their friends' phones magically pop up on their screen for them to add with one tap.

Credits
===========
SimpleShare was created by Laura Skelton.

Features
===========
* Easiest way to share items with nearby friends
* Shares an array of item IDs over Bluetooth LE
* Best way to allow users to join groups based on proximity
* Shares info even when the app is in background mode (unlike iBeacons)

Installation
===========
* Open the SimpleShare Demo project and your XCode project
* Drag the "SimpleShare" directory to your project (Make sure "Copy items into destination group folder", "Create groups for any added folders", and your target are all selected.)
* Add the CoreBluetooth framework to your project (Under Build Phases -> Link Binary With Libraries, click the "+" to add "CoreBluetooth.framework" to your project.)
* In your app's Info.plist file, add "Required Background Modes" -> "App shares data using CoreBluetooth", if you would like your devices that are sharing items to keep sharing even if they are in background mode.
* Create a unique UUID to identify your app in SimpleShare. You can generate one here: http://www.uuidgenerator.net . Then plug it in to your application (after importing SimpleShare.h in any file you use SimpleShare in).

```objc
#import "SimpleShare/SimpleShare.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SimpleShare sharedInstance].simpleShareAppID = @"your-uuid-goes-here";
    return YES;
}
```

Usage
===========
See the SimpleShare Demo app for examples.

For simplicity, the SimpleShare Demo generates random UUIDs and shares them with nearby friends using the app. In a real app, you would probably get a user's items (such as their photo album IDs, or group IDs) from a web server, share those items with nearby friends, and then download the item details using the itemIDs from the server on your friend's phone.

Usage Examples:

```objc
#import "SimpleShare/SimpleShare.h"

@interface MyViewController : UITableViewController <SimpleShareDelegate>

@property (nonatomic, retain) NSMutableArray *myItemIDs;

@end

@implementation MyViewController
@sythesize myItemIDs;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Normally we'd get this array from a server that sends us a list of the user's items. For simplicity we're just creating a randomly generated array of item ID's to share.
    self.myItemIDs = [[NSMutableArray alloc] initWithObjects:[[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], nil];

    // Tell SimpleShare the item IDs we are sharing
    [SimpleShare sharedInstance].delegate = self; // lets this file receive delegate messages, such as the following:

    [SimpleShare sharedInstance].myItemIDs = self.myItemIDs; // send the array of itemIDs you are sharing to SimpleShare

}

#pragma mark - SimpleShare Delegate

- (void)simpleShareFoundFirstItems:(NSArray *)itemIDs
{
    // get rid of old found nearby items
    _nearbyItems = nil;

    _nearbyItems = [[NSMutableArray alloc] init];

    // add the first items to the array
    [_nearbyItems addObjectsFromArray:itemIDs];

    // pop up nearby items controller to show found items
    [self performSegueWithIdentifier:@"addNearbyItems" sender:self];
}

- (void)simpleShareFoundMoreItems:(NSArray *)itemIDs
{
    // add the new items to the array
    [_nearbyItems addObjectsFromArray:itemIDs];

    // update nearby items controller
    [_nearbyItemsController setNearbyItemIDs:_nearbyItems];
    [_nearbyItemsController.tableView reloadData];
}

- (void)simpleShareFoundNoItems:(SimpleShare *)simpleShare
{
    // update UI to show it is done looking for items
    [self.navigationItem setRightBarButtonItem:_findItemsButton];

}

- (void)simpleShareDidFailWithMessage:(NSString *)failMessage
{
    // update UI to show it is not looking for items
    [self.navigationItem setRightBarButtonItem:_findItemsButton];

    // update UI to indicate it is not sharing items
    _shareItemsButton.title = @"Share";
    _shareItemsButton.action = @selector(shareMyItems:);

}

@end
```

Coming Soon
===========
A second demo app is in the works that will show how to use the shared item IDs to get useful information from one phone to another with bluetooth magic by connecting with a web API.

Future
===========
Since the sharing is simply done over Bluetooth LE, with a comma-separated string of item IDs shared between phones, this should work well cross-platform. An Android version of this project would allow the phones to easily share items regardless of platform.
