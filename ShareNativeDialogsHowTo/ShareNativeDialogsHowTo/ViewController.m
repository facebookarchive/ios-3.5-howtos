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
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *authButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *publishButton;
@property (strong, nonatomic) IBOutlet UIButton *publishOGButton;

@end

@implementation ViewController

@synthesize authButton;

#pragma mark - Helper methods

/*
 * Configure the logged in versus logged out UI
 */
- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        self.publishButton.hidden = NO;
        self.publishOGButton.hidden = NO;
        [self.authButton setTitle:@"Logout" forState:UIControlStateNormal];
    } else {
        self.publishButton.hidden = YES;
        self.publishOGButton.hidden = YES;
        [self.authButton setTitle:@"Login" forState:UIControlStateNormal];
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
    [self setPublishButton:nil];
    [self setPublishOGButton:nil];
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

- (IBAction)publishButtonAction:(id)sender {
    // First check if we can use the native dialog, otherwise will
    // use our own
    BOOL displayedNativeDialog =
    [FBNativeDialogs
     presentShareDialogModallyFrom:self
     initialText:@""
     image:[UIImage imageNamed:@"iossdk_logo.png"]
     url:[NSURL URLWithString:@"https://developers.facebook.com/ios"]
     handler:^(FBNativeDialogResult result, NSError *error) {
         
         // Only show the error if it is not due to the dialog
         // not being supporte, i.e. code = 7, otherwise ignore
         // because our fallback will show the share view controller.
         if (error && [error code] == 7) {
             return;
         }
         
         NSString *alertText = @"";
         if (error) {
             alertText = [NSString stringWithFormat:
                          @"error: domain = %@, code = %d",
                          error.domain, error.code];
         } else if (result == FBNativeDialogResultSucceeded) {
             alertText = @"Posted successfully.";
         }
         if (![alertText isEqualToString:@""]) {
             // Show the result in an alert
             [[[UIAlertView alloc] initWithTitle:@"Result"
                                         message:alertText
                                        delegate:self
                               cancelButtonTitle:@"OK!"
                               otherButtonTitles:nil]
              show];
         }
    }];
    
    // Fallback, show the view controller that will post using me/feed
    if (!displayedNativeDialog) {
        ShareViewController *viewController =
        [[ShareViewController alloc] initWithNibName:@"ShareViewController"
                                              bundle:nil];
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    }
}

- (IBAction)publishOGButtonAction:(id)sender {

    /*NSDictionary *objectProperties = @{@"price": @"600",
                                      @"event": @"UEFA Championships"
                                      };
    //http://www.freebestwallpapers.info/bulkupload//New072010//Sports/HD-Soccer-10.jpg
    //https://furious-mist-4378.herokuapp.com/images/Uefa-Champions-League-Smaller.jpeg
    NSDictionary* object = @{
                             @"fbsdk:create_object_of_type": @"openforgraph:ticket",
                             @"title": @"UEFA Champions League Finals",
                             @"image": @"http://www.freebestwallpapers.info/bulkupload//New072010//Sports/HD-Soccer-10.jpg",
                             @"description": @"The semifinals of the UEFA Champions League.",
                             @"data": objectProperties
                             };
    
    id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
    [place setId:@"191206170926721"]; // Facebook Menlo Park
    
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    [action setObject:object forKey:@"ticket"]; // set action's ticket property
    [action setPlace:place]; // set place tag
    [action setTags:@[@"100003086810435"]]; // set user tags
    
    [FBNativeDialogs presentFBShareDialogWithOpenGraphAction:action
                                                  actionType:@"openforgraph:want"
                                         previewPropertyName:@"ticket"
                                                 clientState:NULL
                                                     handler:^(FBAppCall *action, NSDictionary *results, NSError *error) {
                                                         if(error) {
                                                             NSLog(@"Error: %@", error.description);
                                                         } else {
                                                             NSLog(@"Success!");
                                                         }
                                                     }];*/
    
    NSDictionary* object = @{
                             @"fbsdk:create_object": @YES,
                             @"type": @"openforgraph:challenge",
                             @"title": @"Eight Week Fitness Challenge",
                             @"image": @"http://rockcityfitness.net/wp/wp-content/uploads/2012/05/group-pt.jpg",
                             @"description": @"Get into the habit of exercising regularly at least 5 days a week for the next 8 weeks. Let's do this!"
                             };
    
    //id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
    //[place setId:@"191206170926721"]; // Facebook Menlo Park
    
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    
    [action setObject:object forKey:@"challenge"]; // set action's challenge property
    
    //[action setPlace:place]; // set place tag
    //[action setTags:@[@"100003086810435"]]; // set user tags
    
    [FBDialogs presentShareDialogWithOpenGraphAction:action
                                                  actionType:@"openforgraph:create"
                                         previewPropertyName:@"challenge"
                                                     handler:^(FBAppCall *action, NSDictionary *results, NSError *error) {
                                                         if(error) {
                                                             NSLog(@"Error: %@", error.description);
                                                         } else {
                                                             NSLog(@"Success!");
                                                         }
                                                     }];
    
    // 0-316-31696-2
    // The Tipping Point: How Little Things Can Make a Big Difference
    // Malcolm Gladwell
    // http://upload.wikimedia.org/wikipedia/en/7/73/Thetippingpoint.jpg
    
    // Set up the object, a book with the required properties
    /*NSDictionary *objectProperties = @{@"isbn": @"0-316-31696-2"};
    NSDictionary* object = @{
                             @"type": @"books.book",
                             @"FBPostObject": @"true",
                             @"title": @"The Tipping Point",
                             @"url" : @"https://furious-mist-4378.herokuapp.com/books/tipping/",
                             @"image": @"http://upload.wikimedia.org/wikipedia/en/7/73/Thetippingpoint.jpg",
                             @"description": @"How Little Things Can Make a Big Difference",
                             @"data": objectProperties                             
                             };
    
    // Create an action
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    // Connect the action to the defined object
    [action setObject:object forKey:@"book"];
    //169246763229885
    //[action setObject:@"169246763229885" forKey:@"book"];
    
    // Show the share dialog to publish the book read action
    [FBDialogs presentShareDialogWithOpenGraphAction:action
                                          actionType:@"books.reads"
                                 previewPropertyName:@"book"
                                             handler:
     ^(FBAppCall *call, NSDictionary *results, NSError *error) {
        if(error) {
            NSLog(@"Error: %@", error.description);
        } else {
            NSLog(@"Success!");
        }
    }];*/

    
    /*NSDictionary* object = @{
                             @"fbsdk:create_object_of_type": @"snsocialhiking:trail",
                             @"title": @"Whistler Peak",
                             @"data": @{ @"location": @{@"latitude": @"48.515414",
                                                        @"longitude": @"-120.707605",
                                                        } },
                             };
    
    id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
    [place setId:@"11092928401"];
    
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    [action setObject:object forKey:@"trail"]; // object tag
    [action setPlace:place]; // place tag
    [action setTags:@[@"566480611"]]; // user tags
    
    [FBNativeDialogs presentFBShareDialogWithOpenGraphAction:action
                                                  actionType:@"snsocialhiking:hike"
                                         previewPropertyName:@"trail"
                                                 clientState:NULL
                                                     handler:^(FBAppCall *action, NSDictionary *results,
                                                               NSError *error) {
                                                         NSLog(@"Back from block: %@ %@", error.description, error.fberrorUserMessage);
                                                     }];*/
}

@end