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
#import "FriendProtocols.h"

@interface ViewController ()
<FBFriendPickerDelegate>
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *selectFriendsButton;

@end

@implementation ViewController

@synthesize selectFriendsButton;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Ask for the required permissions
    self.loginView.readPermissions = @[@"basic_info"];
}

- (void)viewDidUnload
{
    [self setSelectFriendsButton:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Action methods

- (IBAction)selectFriendsButtonAction:(id)sender {
    // Initialize the friend picker
    FBFriendPickerViewController *friendPickerController =
    [[FBFriendPickerViewController alloc] init];
    
    // Configure the picker ...
    friendPickerController.title = @"Select Friends";
    // Set this view controller as the friend picker delegate
    friendPickerController.delegate = self;
    // Ask for friend device data
    friendPickerController.fieldsForRequest =
        [NSSet setWithObjects:@"devices", nil];
    
    // Fetch the data
    [friendPickerController loadData];
    
    // Present view controller modally
    [self presentViewController:friendPickerController
                       animated:YES
                     completion:nil];
}

/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.selectFriendsButton.hidden = NO;
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.selectFriendsButton.hidden = YES;
}

#pragma mark - FBFriendPickerViewController delegate methods
- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    NSLog(@"Friend selection cancelled.");
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    FBFriendPickerViewController *fpc = (FBFriendPickerViewController *)sender;
    for (id<FBGraphUser> user in fpc.selection) {
        NSLog(@"Friend selected: %@", user.name);
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id<FBGraphUserExtraFields>)user
{
    NSArray *deviceData = user.devices;
    // Loop through list of devices for the friend
    for (NSDictionary *deviceObject in deviceData) {
        // Check if there is a device match
        if ([@"iOS" isEqualToString:deviceObject[@"os"]]) {
            // Friend is an iOS user, include them in the display
            return YES;
        }
    }
    // Friend is not an iOS user, do not include them
    return NO;
}

@end
