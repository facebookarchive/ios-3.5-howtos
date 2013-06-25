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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *sendRequestButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *sendRequestiOSButton;

@end

@implementation ViewController

@synthesize sendRequestButton;
@synthesize sendRequestiOSButton;

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
    [self setSendRequestButton:nil];
    [self setSendRequestiOSButton:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Action methods

- (IBAction)sendRequestButtonAction:(id)sender {
    AppDelegate *appDelegate =
    (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if (FBSession.activeSession.isOpen) {
        [appDelegate sendRequest];
    }
}

- (IBAction)sendRequestiOSButtonAction:(id)sender {
    AppDelegate *appDelegate =
    (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if (FBSession.activeSession.isOpen) {
        [appDelegate sendRequestToiOSFriends];
    }
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.sendRequestButton.hidden = NO;
    self.sendRequestiOSButton.hidden = NO;
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.sendRequestButton.hidden = YES;
    self.sendRequestiOSButton.hidden = YES;
}

@end
