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
#import "FriendViewController.h"

@interface ViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *authButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *queryButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *multiQueryButton;

@end

@implementation ViewController

@synthesize authButton;
@synthesize queryButton;
@synthesize multiQueryButton;

#pragma mark - Helper methods

/*
 * Configure the logged in versus logged out UI
 */
- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        [self.authButton setTitle:@"Logout" forState:UIControlStateNormal];
        self.queryButton.hidden = NO;
        self.multiQueryButton.hidden = NO;
    } else {
        [self.authButton setTitle:@"Login" forState:UIControlStateNormal];
        self.queryButton.hidden = YES;
        self.multiQueryButton.hidden = YES;
    }
}

/*
 * Present the friend details display view controller
 */
- (void) showFriends:(NSArray *)friendData
{
    // Set up the view controller that will show friend information
    FriendViewController *viewController =
    [[FriendViewController alloc] initWithStyle:UITableViewStylePlain];
    viewController.data = friendData;
    // Present view controller modally.
    if ([self
         respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS 5+
        [self presentViewController:viewController animated:YES completion:nil];
    } else {
        [self presentModalViewController:viewController animated:YES];
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
    [self setQueryButton:nil];
    [self setMultiQueryButton:nil];
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

- (IBAction)queryButtonAction:(id)sender {
    // Query to fetch the active user's friends, limit to 25.
    NSString *query =
    @"SELECT uid, name, pic_square FROM user WHERE uid IN "
    @"(SELECT uid2 FROM friend WHERE uid1 = me() LIMIT 25)";
    // Set up the query parameter
    NSDictionary *queryParam =
    [NSDictionary dictionaryWithObjectsAndKeys:query, @"q", nil];
    // Make the API request that uses FQL
    [FBRequestConnection startWithGraphPath:@"/fql"
                                 parameters:queryParam
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (error) {
                                  NSLog(@"Error: %@", [error localizedDescription]);
                              } else {
                                  NSLog(@"Result: %@", result);
                                  // Get the friend data to display
                                  NSArray *friendInfo = (NSArray *) [result objectForKey:@"data"];
                                  // Show the friend details display
                                  [self showFriends:friendInfo];
                              }
                          }];
}

- (IBAction)multiQueryButtonAction:(id)sender {
    // Multi-query to fetch the active user's friends, limit to 25.
    // The initial query is stored in reference named "friends".
    // The second query picks up the "uid2" info from the first
    // query and gets the friend details.
    NSString *query =
    @"{"
    @"'friends':'SELECT uid2 FROM friend WHERE uid1 = me() LIMIT 25',"
    @"'friendinfo':'SELECT uid, name, pic_square FROM user WHERE uid IN (SELECT uid2 FROM #friends)',"
    @"}";
    // Set up the query parameter
    NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q", nil];
    // Make the API request that uses FQL
    [FBRequestConnection startWithGraphPath:@"/fql"
                                 parameters:queryParam
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (error) {
                                  NSLog(@"Error: %@", [error localizedDescription]);
                              } else {
                                  NSLog(@"Result: %@", result);
                                  // Get the friend data to display
                                  NSArray *friendInfo =
                                  (NSArray *) [[[result objectForKey:@"data"]
                                                objectAtIndex:1]
                                               objectForKey:@"fql_result_set"];
                                  // Show the friend details display
                                  [self showFriends:friendInfo];
                              }
                          }];
}

@end
