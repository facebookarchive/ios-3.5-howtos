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
#import "ShareViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;
@property (weak, nonatomic) IBOutlet UIButton *shareWebFallbackButton;
@property (weak, nonatomic) IBOutlet UIButton *shareAPIFallbackButton;
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

- (void)viewDidUnload {
    [self setShareWebFallbackButton:nil];
    [self setShareAPIFallbackButton:nil];
    [self setLoginView:nil];
    [super viewDidUnload];
}

#pragma mark - Share Methods

/*
 * Method invoked when the share button is clicked
 */
- (IBAction)shareButtonAction:(id)sender {    
    // First attempt: Publish using the Facenook Share dialog
    FBAppCall *call = [self publishWithShareDialog];
    
    // Second fallback: Publish using the iOS6 OS Integrated Share dialog
    BOOL displayedNativeDialog = YES;
    if (!call) {
        displayedNativeDialog =[self publishWithOSIntegratedShareDialog];
    }
    
    // Third fallback: Publish using either the Graph API or the Web Dialog
    if (!call && !displayedNativeDialog) {
        if ([sender tag] == 0) {
            // The Web Dialog share button tag is set to "0"
            [self publishWithWebDialog];
        } else {
            // The API share button tag is set to "1"
            ShareViewController *viewController =
            [[ShareViewController alloc] initWithNibName:@"ShareViewController"
                                                  bundle:nil];
            [self presentViewController:viewController
                               animated:YES
                             completion:nil];
        }
    }
}

/*
 * Share using the Facebook native Share Dialog
 */
- (FBAppCall *) publishWithShareDialog {
    // Set up the dialog parameters
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.link = [NSURL URLWithString:@"https://developers.facebook.com/ios"];
    params.picture = [NSURL
                      URLWithString:@"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"];
    params.name = @"Facebook SDK for iOS";
    params.caption = @"Build great social apps and get more installs.";
    params.description = @"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.";
    return [FBDialogs presentShareDialogWithParams:params
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
}

/*
 * Share using the iOS6 Share Sheet
 */
- (BOOL) publishWithOSIntegratedShareDialog {
    return [FBDialogs
            presentOSIntegratedShareDialogModallyFrom:self
            initialText:@""
            image:nil
            url:[NSURL URLWithString:@"https://developers.facebook.com/ios"]
            handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
                // Only show the error if it is not due to the dialog
                // not being supported, otherwise ignore because our fallback
                // will show the share view controller.
                if ([[error userInfo][FBErrorDialogReasonKey]
                     isEqualToString:FBErrorDialogNotSupported]) {
                    return;
                }
                if (error) {
                    [self showAlert:[self checkErrorMessage:error]];
                } else if (result == FBNativeDialogResultSucceeded) {
                    [self showAlert:@"Posted successfully."];
                }
    }];
}

/*
 * Share using the Web Dialog
 */
- (void) publishWithWebDialog {
    // Put together the dialog parameters
    NSMutableDictionary *params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @"Facebook SDK for iOS", @"name",
     @"Build great social apps and get more installs.", @"caption",
     @"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.", @"description",
     @"https://developers.facebook.com/ios", @"link",
     @"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png", @"picture",
     nil];
    
    // Invoke the dialog
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:
     ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or publishing a story.
             [self showAlert:[self checkErrorMessage:error]];
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled story publishing.");
             } else {
                 // Handle the publish feed callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"post_id"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled story publishing.");
                 } else {
                     // User clicked the Share button
                     [self showAlert:[self checkPostId:urlParams]];
                 }
             }
         }
     }];
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
    // Share Dialog
    NSString *postId = results[@"postId"];
    if (!postId) {
        // Web Dialog
        postId = results[@"post_id"];
    }
    if (postId) {
        message = [NSString stringWithFormat:@"Posted story, id: %@", postId];
    }
    return message;
}

/*
 * Helper method to parse URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
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
    self.shareWebFallbackButton.hidden = NO;
    self.shareAPIFallbackButton.hidden = NO;
}

/*
 * Handle the logged out scenario
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.shareWebFallbackButton.hidden = NO;
    self.shareAPIFallbackButton.hidden = YES;
}

@end
