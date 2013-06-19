/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ViewController.h"
#import "AppDelegate.h"
#import "CacheProtocols.h"
#import <CoreLocation/CoreLocation.h> 

@interface ViewController ()
<FBFriendPickerDelegate,
FBPlacePickerDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *showFriendsButton;
@property (readwrite, copy, nonatomic) NSSet *extraFieldsForFriendRequest;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *showNearbyButton;
@property (assign, nonatomic) CLLocationCoordinate2D searchLocation;

@end

@implementation ViewController

@synthesize showFriendsButton;
@synthesize showNearbyButton;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Ask for the required permissions
    self.loginView.readPermissions = @[@"basic_info", @"friends_about_me"];
    
    // Extra information to fetch for friends
    self.extraFieldsForFriendRequest = [NSSet setWithObjects:@"bio", nil];
    
    // Set current location to Facebook HQ
    self.searchLocation = CLLocationCoordinate2DMake(37.483253, -122.150037);
}

- (void)viewDidUnload
{
    [self setShowFriendsButton:nil];
    [self setShowNearbyButton:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Action methods

- (IBAction)showFriendsAction:(id)sender {
    // Initialize the friend picker
    FBFriendPickerViewController *friendPickerController = [[FBFriendPickerViewController alloc] init];
    
    // Configure the picker ...
    friendPickerController.title = @"Show Friends";
    // Set this view controller as the friend picker delegate
    friendPickerController.delegate = self;
    // Allow only a single friend to be selected
    friendPickerController.allowsMultipleSelection = NO;
    
    // Set the extra info to get for friends
    friendPickerController.fieldsForRequest = self.extraFieldsForFriendRequest;
    
    // Fetch the data
    [friendPickerController loadData];
    
    // Present view controller modally.e the deprecated
    if ([self
         respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS 5+
        [self presentViewController:friendPickerController animated:YES completion:nil];
    } else {
        [self presentModalViewController:friendPickerController animated:YES];
    }
}

- (IBAction)showNearbyAction:(id)sender {
    // Initialize the place picker
    FBPlacePickerViewController *placePickerController =
    [[FBPlacePickerViewController alloc] init];
    
    // Configure the picker ...
    placePickerController.title = @"Show Nearby";
    // Set this view controller as the place picker delegate
    placePickerController.delegate = self;
    // Set the search criteria
    placePickerController.locationCoordinate = self.searchLocation;
    placePickerController.radiusInMeters = 1000;
    placePickerController.resultsLimit = 20;
    
    // Fetch the data
    [placePickerController loadData];
    
    // Present view controller modally.
    if ([self
         respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS 5+
        [self presentViewController:placePickerController animated:YES completion:nil];
    } else {
        [self presentModalViewController:placePickerController animated:YES];
    }
}

#pragma mark - FBFriendPickerDelegate methods
- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    [self dismissModalViewControllerAnimated:YES];
    if (friendPicker.selection) {
        NSArray *friends = friendPicker.selection;
        id<CacheGraphFriend> friend = [friends objectAtIndex:0];
        
        NSString *message = @"";
        if (friend.bio && ![friend.bio isEqualToString:@""]) {
            message = [message stringByAppendingString:friend.bio];
        }
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:friend.first_name
                              message:message
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - FBPlacePickerDelegate
- (void)placePickerViewControllerSelectionDidChange:
(FBPlacePickerViewController *)placePicker
{
    [self dismissModalViewControllerAnimated:YES];
    if (placePicker.selection) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:placePicker.selection.name
                              message:[NSString
                                       stringWithFormat:@"%@, %@",
                                       placePicker.selection.location.city,
                                       placePicker.selection.location.state]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - LoginView Delegate Methods

/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.showFriendsButton.hidden = NO;
    self.showNearbyButton.hidden = NO;
    
    // Cache friend data
    FBCacheDescriptor  *friendCacheDescriptor = [FBFriendPickerViewController
                                                 cacheDescriptorWithUserID:nil
                                                 fieldsForRequest:self.extraFieldsForFriendRequest];
    [friendCacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
    
    // Cache nearby place data
    FBCacheDescriptor *placeCacheDescriptor =
    [FBPlacePickerViewController
     cacheDescriptorWithLocationCoordinate:self.searchLocation
     radiusInMeters:1000
     searchText:nil
     resultsLimit:20
     fieldsForRequest:nil];
    [placeCacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.showFriendsButton.hidden = YES;
    self.showNearbyButton.hidden = YES;
}

@end
