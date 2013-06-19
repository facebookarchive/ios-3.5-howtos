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
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *postMessageTextView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *postButton;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ViewController

@synthesize postMessageTextView;
@synthesize postButton;
@synthesize statusLabel;

#pragma mark - Helper methods

/*
 * Post status update and read in updated status
 */
- (void) updateStatus
{
    [FBSettings setLoggingBehavior:[NSSet setWithObject:FBLoggingBehaviorFBRequests]];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    // First request posts a status update
    //
    // Hint: If you're testing and don't want to spam your friends, add
    // this additional parameter to post to "Only Me".
    // @"{'value': 'SELF'}", @"privacy",
    NSDictionary *request1Params = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:
                                    self.postMessageTextView.text, @"message",
                                    nil];
    FBRequest *request1 =
    [FBRequest requestWithGraphPath:@"me/feed"
                         parameters:request1Params
                         HTTPMethod:@"POST"];
    [connection addRequest:request1
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error) {
         }
     }
            batchEntryName:@"status-post"
     ];
    
    // Second request retrieves the status posted
    FBRequest *request2 = [FBRequest requestForGraphPath:
                           @"{result=status-post:$.id}"];
    [connection addRequest:request2
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error &&  result) {
             self.statusLabel.text = [result objectForKey:@"message"];
         }
         // Clear text input.
         self.postMessageTextView.text = @"";
     }
     ];
    
    [connection start];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Ask for the required permissions
    self.loginView.readPermissions = @[@"basic_info", @"read_stream"];
}

- (void)viewDidUnload
{
    [self setPostMessageTextView:nil];
    [self setPostButton:nil];
    [self setStatusLabel:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/*
 * A simple way to dismiss the message text view:
 * whenever the user clicks outside the view.
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.postMessageTextView isFirstResponder] &&
        (self.postMessageTextView != touch.view))
    {
        [self.postMessageTextView resignFirstResponder];
    }
}

#pragma mark - Action methods
- (IBAction)postButtonAction:(id)sender {
    if (![self.postMessageTextView.text isEqualToString:@""]) {
        // Ask for publish_actions permissions in context
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound) {
            // No permissions found in session, ask for it
            [FBSession.activeSession
             requestNewPublishPermissions:
             [NSArray arrayWithObject:@"publish_actions"]
             defaultAudience:FBSessionDefaultAudienceFriends
             completionHandler:^(FBSession *session, NSError *error) {
                 if (!error) {
                     // If permissions granted, update the status
                     [self updateStatus];
                 }
             }];
        } else {
            // If permissions present, update the status
            [self updateStatus];
        }
    }
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.postButton.hidden = NO;
    self.postMessageTextView.hidden = NO;
    self.statusLabel.hidden = NO;
    
    // Get the most recent status
    [FBRequestConnection
     startWithGraphPath:@"me/statuses?limit=1"
     completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {
         if (!error) {
             // Set the status label
             if (result[@"data"] && [result[@"data"] count] > 0) {
                 self.statusLabel.text = result[@"data"][0][@"message"];
             }
         }
     }];
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.postButton.hidden = YES;
    self.postMessageTextView.hidden = YES;
    self.statusLabel.hidden = YES;
}

@end
