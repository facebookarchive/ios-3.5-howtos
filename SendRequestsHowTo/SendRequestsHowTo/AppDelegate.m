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

#import "AppDelegate.h"

#import "ViewController.h"

#import "FBSBJSON.h"

NSString *const FBSessionStateChangedNotification =
@"com.facebook.samples.SendRequestsHowTo:FBSessionStateChangedNotification";

@interface AppDelegate ()
<UIAlertViewDelegate>

@property (nonatomic, assign) BOOL appUsageCheckEnabled;
@property (nonatomic, retain) NSURL *openedURL;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize appUsageCheckEnabled = _appUsageCheckEnabled;
@synthesize openedURL = _openedURL;

#pragma mark - Helper methods

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                //NSLog(@"User session found");
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

/*
 * Opens a Facebook session and optionally shows the login UX.
 */
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    return [FBSession openActiveSessionWithReadPermissions:nil
                                                 allowLoginUI:allowLoginUI
                                            completionHandler:^(FBSession *session,
                                                                FBSessionState state,
                                                                NSError *error) {
                                                [self sessionStateChanged:session
                                                                    state:state
                                                                    error:error];
                                            }];
}

/*
 *
 */
- (void) closeSession {
    [FBSession.activeSession closeAndClearTokenInformation];
}

/*
 * This private method will be used to check the app
 * usage counter, update it as necessary, and return
 * back an indication on whether the user should be
 * shown the prompt to invite friends
 */
- (BOOL) checkAppUsageTrigger {
    // Initialize the app active count
    NSInteger appActiveCount = 0;
    // Read the stored value of the counter, if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"AppUsedCounter"]) {
        appActiveCount = [defaults integerForKey:@"AppUsedCounter"];
    }
    
    // Increment the counter
    appActiveCount++;
    BOOL trigger = NO;
    // Only trigger the prompt if the facebook session is valid and
    // the counter is greater than a certain value, 3 in this sample
    if (FBSession.activeSession.isOpen && (appActiveCount >= 3)) {
        trigger = YES;
        appActiveCount = 0;
    }
    // Save the updated counter
    [defaults setInteger:appActiveCount forKey:@"AppUsedCounter"];
    [defaults synchronize];
    return trigger;
}

/**
 * A function for parsing URL parameters.
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
 * Send a request to get only iOS users. Used to target requests.
 */
- (void) requestFriendsUsingDevice:(NSString *)device {
    NSMutableArray *deviceFilteredFriends = [[NSMutableArray alloc] init];
    [FBRequestConnection startWithGraphPath:@"me/friends"
                                 parameters:[NSDictionary
                                             dictionaryWithObjectsAndKeys:
                                             @"id,devices", @"fields",
                                             nil]
                                 HTTPMethod:nil
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (!error) {
                                  // Get the result
                                  NSArray *resultData = [result objectForKey:@"data"];
                                  // Check we have data
                                  if ([resultData count] > 0) {
                                      // Loop through the friends returned
                                      for (NSDictionary *friendObject in resultData) {
                                          // Check if devices info available
                                          if ([friendObject objectForKey:@"devices"]) {
                                              NSArray *deviceData = [friendObject
                                                                     objectForKey:@"devices"];
                                              // Loop through list of devices
                                              for (NSDictionary *deviceObject in deviceData) {
                                                  // Check if there is a device match
                                                  if ([device isEqualToString:
                                                       [deviceObject objectForKey:@"os"]]) {
                                                      // If there is a match, add it to the list
                                                      [deviceFilteredFriends addObject:
                                                       [friendObject objectForKey:@"id"]];
                                                      break;
                                                  }
                                              }
                                          }
                                      }
                                  }
                              }
                              // Send request
                              [self sendRequest:deviceFilteredFriends];
                          }];
}

/*
 * Send a user to user request
 */
- (void)sendRequest {
    FBSBJSON *jsonWriter = [FBSBJSON new];
    NSDictionary *gift = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"5", @"social_karma",
                          @"1", @"badge_of_awesomeness",
                          nil];
    
    NSString *giftStr = [jsonWriter stringWithObject:gift];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   giftStr, @"data",
                                   nil];
    
    // Display the requests dialog
    [FBWebDialogs
     presentRequestsDialogModallyWithSession:nil
     message:@"Learn how to make your iOS apps social."
     title:nil
     parameters:params
     handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or sending the request.
             NSLog(@"Error sending request.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled request.");
             } else {
                 // Handle the send request callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"request"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled request.");
                 } else {
                     // User clicked the Send button
                     NSString *requestID = [urlParams valueForKey:@"request"];
                     NSLog(@"Request ID: %@", requestID);
                 }
             }
         }
    }];
}

- (void)sendRequestToiOSFriends {
    // Filter and only show friends using iOS
    [self requestFriendsUsingDevice:@"iOS"];
}

/*
 * Send a user to user request, with a targeted list
 */
- (void)sendRequest:(NSArray *) targeted {
    FBSBJSON *jsonWriter = [FBSBJSON new];
    NSDictionary *gift = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"5", @"social_karma",
                          @"1", @"badge_of_awesomeness",
                          nil];
    
    NSString *giftStr = [jsonWriter stringWithObject:gift];
    NSMutableDictionary* params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:giftStr, @"data",
     nil];
    
    // Filter and only show targeted friends
    if (targeted != nil && [targeted count] > 0) {
        NSString *selectIDsStr = [targeted componentsJoinedByString:@","];
        [params setObject:selectIDsStr forKey:@"suggestions"];
    }
    
    // Display the requests dialog
    [FBWebDialogs
     presentRequestsDialogModallyWithSession:nil
     message:@"Learn how to make your iOS apps social."
     title:nil
     parameters:params
     handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or sending request.
             NSLog(@"Error sending request.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled request.");
             } else {
                 // Handle the send request callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"request"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled request.");
                 } else {
                     // User clicked the Send button
                     NSString *requestID = [urlParams valueForKey:@"request"];
                     NSLog(@"Request ID: %@", requestID);
                 }
             }
         }
     }];
}

/*
 * Helper function to get the request data
 */
- (void) notificationGet:(NSString *)requestid {
    [FBRequestConnection startWithGraphPath:requestid
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (!error) {
                                  NSString *title;
                                  NSString *message;
                                  if ([result objectForKey:@"data"]) {
                                      title = [NSString
                                               stringWithFormat:@"%@ sent you a gift",
                                               [[result objectForKey:@"from"]
                                                objectForKey:@"name"]];
                                      FBSBJSON *jsonParser = [FBSBJSON new];
                                      NSDictionary *requestData =
                                      [jsonParser
                                       objectWithString:[result objectForKey:@"data"]];
                                      message =
                                      [NSString stringWithFormat:@"Badge: %@, Karma: %@",
                                       [requestData objectForKey:@"badge_of_awesomeness"],
                                       [requestData objectForKey:@"social_karma"]];
                                  } else {
                                      title = [NSString
                                               stringWithFormat:@"%@ sent you a request",
                                               [[result objectForKey:@"from"] objectForKey:@"name"]];
                                      message = [NSString stringWithString:
                                                 [result objectForKey:@"message"]];
                                  }
                                  UIAlertView *alert = [[UIAlertView alloc]
                                                        initWithTitle:title
                                                        message:message
                                                        delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil,
                                                        nil];
                                  [alert show];
                                  
                                  // Delete the request notification
                                  [self notificationClear:[result objectForKey:@"id"]];
                              }
                          }];
}

/*
 * Helper function to check incoming URL
 */
- (void) checkIncomingNotification {
    if (self.openedURL) {
        NSString *query = [self.openedURL fragment];
        if (!query) {
            query = [self.openedURL query];
        }
        NSDictionary *params = [self parseURLParams:query];
        // Check target URL exists
        NSString *targetURLString = [params valueForKey:@"target_url"];
        if (targetURLString) {
            NSURL *targetURL = [NSURL URLWithString:targetURLString];
            NSDictionary *targetParams = [self parseURLParams:[targetURL query]];
            NSString *ref = [targetParams valueForKey:@"ref"];
            // Check for the ref parameter to check if this is one of
            // our incoming news feed link, otherwise it can be an
            // an attribution link
            if ([ref isEqualToString:@"notif"]) {
                // Get the request id
                NSString *requestIDParam = [targetParams
                                            objectForKey:@"request_ids"];
                NSArray *requestIDs = [requestIDParam 
                                       componentsSeparatedByString:@","];
                
                // Get the request data from a Graph API call to the
                // request id endpoint
                [self notificationGet:[requestIDs objectAtIndex:0]];
            }
        }
        // Clean out to avoid duplicate calls
        self.openedURL = nil;
    }
}

/*
 * Helper function to delete the request notification
 */
- (void) notificationClear:(NSString *)requestid {
    // Delete the request notification
    [FBRequestConnection startWithGraphPath:requestid
                     parameters:nil
                     HTTPMethod:@"DELETE"
              completionHandler:^(FBRequestConnection *connection,
                                  id result,
                                  NSError *error) {
                  if (!error) {
                      NSLog(@"Request deleted");
                  }
              }];
}

#pragma mark - UIApplication methods
/*
 * If we have a valid session at the time of openURL call, we handle
 * Facebook transitions by passing the url argument to handleOpenURL
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    self.openedURL = url;
    // attempt to extract a token from the url
    return [FBSession.activeSession handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // We will remember the user's setting if they do not wish to
    // send any more invites.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.appUsageCheckEnabled = YES;
    if ([defaults objectForKey:@"AppUsageCheck"]) {
        self.appUsageCheckEnabled = [defaults boolForKey:@"AppUsageCheck"];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // We need to properly handle activation of the application with regards to SSO
    // (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
    
    // Check the flag for enabling any prompts. If that flag is on
    // check the app active counter
    if (self.appUsageCheckEnabled && [self checkAppUsageTrigger]) {
        // If the user should be prompter to invite friends, show
        // an alert with the choices.
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Invite Friends"
                              message:@"If you enjoy using this app, would you mind taking a moment to invite a few friends that you think will also like it?"
                              delegate:self
                              cancelButtonTitle:@"No Thanks"
                              otherButtonTitles:@"Tell Friends!", @"Remind Me Later", nil];
        [alert show];
    }
    
    if (FBSession.activeSession.isOpen) {
        // Check for any incoming notifications
        [self checkIncomingNotification];
    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // if the app is going away, we close the session object
    [FBSession.activeSession close];
}

#pragma mark - UIAlertViewDelegate methods
/*
 * When the alert is dismissed check which button was clicked so
 * you can take appropriate action, such as displaying the request
 * dialog, or setting a flag not to prompt the user again.
 */

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // User has clicked on the No Thanks button, do not ask again
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"AppUsageCheck"];
        [defaults synchronize];
        self.appUsageCheckEnabled = NO;
    } else if (buttonIndex == 1) {
        // User has clicked on the Tell Friends button
        [self performSelector:@selector(sendRequest)
                   withObject:nil afterDelay:0.5];
    }
}

@end
