/*
 * Copyright 2013 Facebook
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

typedef void (^MyAppBlock)(void);

@interface ViewController ()
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Ask for the required permissions
    self.loginView.readPermissions = @[@"basic_info"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Share methods
/*
 * Share a link using the Share Dialog
 */
- (IBAction)shareLinkAction:(id)sender {
    // Optional: Make sure user is authenticated and has
    // granted publish action permissions
//    BOOL needPermissions = [self requestPermissionsWithCompletion:^{
//        [self shareLinkAction:nil];
//    }];
//    if (needPermissions)
//    {
//        return;
//    }
    
    // Set up the dialog parameters
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.link = [NSURL URLWithString:@"https://developers.facebook.com/ios"];
    params.picture = [NSURL
                      URLWithString:@"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"];
    params.name = @"Facebook SDK for iOS";
    params.caption = @"Build great social apps and get more installs.";
    params.description = @"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.";
    FBAppCall *call = [FBDialogs presentShareDialogWithParams:params
                                                  clientState:nil
                                                      handler:
                       ^(FBAppCall *call, NSDictionary *results, NSError *error) {
                           if(error) {
                               // If there's an error show the relevant message
                               [self showAlert:[self checkErrorMessage:error]];
                           } else {
                               // Check if cancel info is returned and log the event
                               if (results[@"completionGesture"] &&
                                   [results[@"completionGesture"] isEqualToString:@"cancel"]) {
                                   NSLog(@"User canceled story publishing.");
                               } else {
                                   // If the post went through show a success message
                                   [self showAlert:[self checkPostId:results]];
                               }
                           }
                       }];
    if (!call) {
        [self showAlert:@"Share Dialog not supported. Make sure you're using the latest Facebook app."];
    }
}

/*
 * Share an Open Graph story using the Share Dialog
 */
- (IBAction)shareOGStoryAction:(id)sender {
    // Optional: Make sure user is authenticated and has
    // granted publish action permissions
//    BOOL needPermissions = [self requestPermissionsWithCompletion:^{
//        [self shareOGStoryAction:nil];
//    }];
//    if (needPermissions)
//    {
//        return;
//    }
    
    // Create an action
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    
    // To run this on your own environment:
    // 1. Modify "furious-mist-4378.herokuapp.com" to your own App Domain
    // 2. Enter your App Domain in your Facebook App Dashboard Basic Settings
    // 3. Set the .plist for this app to reference your app ID and other info
    //     - FacebookAppID
    //     - URL types > Item 0 > URL Schemes
    //     - FacebookDisplayName
    //     - Bundle Identifier
    
    // Attach a book object to the action
    action[@"book"] = @{
                        @"type": @"books.book",
                        @"fbsdk:create_object": @YES,
                        @"title": @"A Game of Thrones",
                        @"url": @"https://furious-mist-4378.herokuapp.com/books/a_game_of_thrones/",
                        @"image": [UIImage imageNamed:@"a_game_of_thrones.jpg"],
                        @"description": @"In the frozen wastes to the north of Winterfell, sinister and supernatural forces are mustering.",
                        @"data": @{@"isbn": @"0-553-57340-3"}
                        };
    
    // Show the share dialog to publish the book read action
    FBAppCall *call = [FBDialogs presentShareDialogWithOpenGraphAction:action
                                          actionType:@"books.reads"
                                 previewPropertyName:@"book"
                                             handler:
     ^(FBAppCall *call, NSDictionary *results, NSError *error) {
         if(error) {
             // If there's an error show the relevant message
             [self showAlert:[self checkErrorMessage:error]];
         } else {
             // Check if cancel info is returned and log the event
             if (results[@"completionGesture"] &&
                 [results[@"completionGesture"] isEqualToString:@"cancel"]) {
                 NSLog(@"User canceled story publishing.");
             } else {
                 // If the post went through show a success message
                 [self showAlert:[self checkPostId:results]];
             }
         }
     }];
    if (!call) {
        [self showAlert:@"Share Dialog not supported. Make sure you're using the latest Facebook app."];
    }
}

/*
 * Helper method to make sure the user is logged in and has
 * granted the required permissions. The permissions success path
 * calls a completion method. This method returns true if login 
 * or permissions are required.
 */
- (BOOL)requestPermissionsWithCompletion:(MyAppBlock)completion {
    if (!FBSession.activeSession.isOpen) {
        [[[UIAlertView alloc]
          initWithTitle:@""
          message:@"Please log in with Facebook to share."
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil, nil] show];
        return true;
    } else if ([FBSession.activeSession.permissions
                indexOfObject:@"publish_actions"] == NSNotFound) {
        [FBSession.activeSession
         requestNewPublishPermissions:@[@"publish_actions"]
         defaultAudience:FBSessionDefaultAudienceEveryone
         completionHandler:^(FBSession *session, NSError *error) {
             if (!error) {
                 // Permissions granted. Call the completion method
                 completion();
             } else {
                 NSLog(@"Error: %@", error.description);
             }
         }];
        return true;
    } else {
        return false;
    }
    
}

#pragma mark - Helper methods
/*
 * Helper method to show alert results or errors
 */
- (NSString *)checkErrorMessage:(NSError *)error {
    NSString *errorMessage = @"";
    if (error.fberrorUserMessage) {
        errorMessage = error.fberrorUserMessage;
    } else {
        errorMessage = @"Operation failed due to a connection problem, retry later.";
    }
    return errorMessage;
}

/*
 * Helper method to check for the posted ID
 */
- (NSString *) checkPostId:(NSDictionary *)results {
    NSString *message = @"Posted successfully.";
    if (results[@"postId"]) {
        message = [NSString stringWithFormat:@"Posted story, id: %@", results[@"postId"]];
    }
    return message;
}

/*
 * Helper method to show an alert
 */
- (void)showAlert:(NSString *) alertMsg {
    if (![alertMsg isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@"Result"
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - LoginView Delegate Methods
/*
 * Handle the logged in scenario
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
}

- (void)viewDidUnload {
    [self setLoginView:nil];
    [super viewDidUnload];
}
@end
