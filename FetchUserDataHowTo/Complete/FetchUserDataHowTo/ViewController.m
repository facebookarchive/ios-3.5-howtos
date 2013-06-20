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
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *userInfoTextView;

@end

@implementation ViewController

@synthesize userInfoTextView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Ask for the required permissions
    self.loginView.readPermissions = @[@"basic_info",
                                       @"user_location",
                                       @"user_birthday",
                                       @"user_likes"];
}

- (void)viewDidUnload
{
    [self setUserInfoTextView:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.userInfoTextView.hidden = NO;
    
    // Fetch user data
    [FBRequestConnection
     startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                       id<FBGraphUser> user,
                                       NSError *error) {
         if (!error) {
             NSString *userInfo = @"";
             
             // Example: typed access (name)
             // - no special permissions required
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Name: %@\n\n",
                          user.name]];
             
             // Example: typed access, (birthday)
             // - requires user_birthday permission
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Birthday: %@\n\n",
                          user.birthday]];
             
             // Example: partially typed access, to location field,
             // name key (location)
             // - requires user_location permission
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Location: %@\n\n",
                          user.location[@"name"]]];
             
             // Example: access via key (locale)
             // - no special permissions required
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Locale: %@\n\n",
                          user[@"locale"]]];
             
             // Example: access via key for array (languages)
             // - requires user_likes permission
             if (user[@"languages"]) {
                 NSArray *languages = user[@"languages"];
                 NSMutableArray *languageNames = [[NSMutableArray alloc] init];
                 for (int i = 0; i < [languages count]; i++) {
                     languageNames[i] = languages[i][@"name"];
                 }
                 userInfo = [userInfo
                             stringByAppendingString:
                             [NSString stringWithFormat:@"Languages: %@\n\n",
                              languageNames]];
             }
             
             // Display the user info
             self.userInfoTextView.text = userInfo;
         }
     }];
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.userInfoTextView.hidden = YES;
}
@end
