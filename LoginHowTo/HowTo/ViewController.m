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
#import <FacebookSDK/FBSessionTokenCachingStrategy.h>

@interface ViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *authButton;
@property (strong, nonatomic) IBOutlet UIButton *reauthButton;
@end

@implementation ViewController

@synthesize authButton;

#pragma mark - Helper methods

/*
 * Configure the logged in versus logged out UI
 */
- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        [self.authButton setTitle:@"Logout" forState:UIControlStateNormal];
        self.reauthButton.hidden = NO;
    } else {
        [self.authButton setTitle:@"Login" forState:UIControlStateNormal];
        self.reauthButton.hidden = YES;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Register for notifications on FB session state changes
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:FBSessionStateChangedNotification
     object:nil];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate openSessionWithAllowLoginUI:NO];
}

- (void)viewDidUnload
{
    [self setAuthButton:nil];
    [self setReauthButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Action methods
- (IBAction)authButtonAction:(id)sender {
    AppDelegate *appDelegate =
        [[UIApplication sharedApplication] delegate];
    
    // The user has initiated a login, so call the openSession method
    // and show the login UX if necessary.
    //[appDelegate openSessionWithAllowLoginUI:YES];
    
    // If the user is authenticated, log out when the button is clicked.
    // If the user is not authenticated, log in when the button is clicked.
    if (FBSession.activeSession.isOpen) {
        [appDelegate closeSession];
    } else {
        // The user has initiated a login, so call the openSession method
        // and show the login UX if necessary.
        [appDelegate openSessionWithAllowLoginUI:YES];
    }


}

- (IBAction)reauthButtonAction:(id)sender {
    FBSessionTokenCachingStrategy *tokenCachingStrategy =
    [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName:@"reauth"];
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:nil
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:tokenCachingStrategy];
    [FBSession setActiveSession:session];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [session openWithBehavior:FBSessionLoginBehaviorForcingWebView
            completionHandler:^(FBSession *session,
                                FBSessionState status,
                                NSError *error) {
                if (!error) {
                    [FBRequestConnection
                     startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                                       NSDictionary<FBGraphUser> *user,
                                                       NSError *error) {
                         if (!error) {
                             if ([appDelegate loggedInUserID] == user.id) {
                                 NSLog(@"Matching users");
                             } else {
                                 NSLog(@"Error!! Not logged in user");
                             }
                         } else {
                             NSLog(@"Error getting user info");
                         }
                     }];
                    [FBSession setActiveSession:appDelegate.loggedInSession];
                } else {
                    NSLog(@"Error logging in user with webview");
                }
    }];
}

@end
