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
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *queryButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *multiQueryButton;

@end

@implementation ViewController

@synthesize queryButton;
@synthesize multiQueryButton;

#pragma mark - Helper methods

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
    [self presentViewController:viewController animated:YES completion:nil];
}

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
    [self setQueryButton:nil];
    [self setMultiQueryButton:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Action methods
- (IBAction)queryButtonAction:(id)sender {
    // Query to fetch the active user's friends, limit to 25.
    NSString *query =
    @"SELECT uid, name, pic_square FROM user WHERE uid IN "
    @"(SELECT uid2 FROM friend WHERE uid1 = me() LIMIT 25)";
    // Set up the query parameter
    NSDictionary *queryParam = @{ @"q": query };
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
                                  NSArray *friendInfo = (NSArray *) result[@"data"];
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
    NSDictionary *queryParam = @{ @"q": query };
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
                                  (NSArray *) result[@"data"][1][@"fql_result_set"];
                                  // Show the friend details display
                                  [self showFriends:friendInfo];
                              }
                          }];
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.queryButton.hidden = NO;
    self.multiQueryButton.hidden = NO;
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.queryButton.hidden = YES;
    self.multiQueryButton.hidden = YES;
}

@end
