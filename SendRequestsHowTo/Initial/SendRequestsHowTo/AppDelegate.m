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

@interface AppDelegate ()
<UIAlertViewDelegate>

@property (nonatomic, assign) BOOL appUsageCheckEnabled;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

#pragma mark - UIApplication methods
/*
 * If we have a valid session at the time of openURL call, we handle
 * Facebook transitions by passing the url argument to handleOpenURL
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        // If there is an active session
                        if (FBSession.activeSession.isOpen) {
                            // Do nothing
                        } else if (call.accessTokenData) {
                            // If token data is passed in and there's
                            // no active session, open it from cache
                            [self handleAppLinkToken:call.accessTokenData];
                        }
                    }];
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
    self.appUsageCheckEnabled = NO;
    if ([defaults objectForKey:@"AppUsageCheck"]) {
        self.appUsageCheckEnabled = [defaults boolForKey:@"AppUsageCheck"];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // We need to properly handle activation of the application with regards to SSO
    // (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBAppCall handleDidBecomeActive];
    
    // Check the flag for enabling any prompts. If that flag is on
    // check the app active counter
    if (self.appUsageCheckEnabled && [self checkAppUsageTrigger]) {
        // If the user should be prompter to invite friends, trigger the invite alert view
        // after a short delay to avoid warning related to the UIAlertView possibly blocking
        // the UI at app launch.
        [NSTimer scheduledTimerWithTimeInterval:0.2
                                         target:self
                                       selector:@selector(showInvite)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // if the app is going away, we close the session object
    [FBSession.activeSession close];
}

#pragma mark - Helper methods

/*
 * Helper method to check incoming token data
 */
- (BOOL)handleAppLinkToken:(FBAccessTokenData *)appLinkToken {
    // Initialize a new blank session instance...
    FBSession *appLinkSession = [[FBSession alloc] initWithAppID:nil
                                                     permissions:nil
                                                 defaultAudience:FBSessionDefaultAudienceNone
                                                 urlSchemeSuffix:nil
                                              tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance] ];
    [FBSession setActiveSession:appLinkSession];
    // ... and open it from the App Link's Token.
    return [appLinkSession openFromAccessTokenData:appLinkToken
                                 completionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error) {
                                     // Log any errors
                                     if (error) {
                                         NSLog(@"Error using cached token to open a session: %@",
                                               error.localizedDescription);
                                     }
                                 }];
}

/*
 * Send a user to user request
 */
- (void)sendRequest {

}

/*
 * Send request to iOS device users.
 */
- (void)sendRequestToiOSFriends {

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

/*
 * Helper method to show the invite alert
 */
- (void)showInvite
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Invite Friends"
                          message:@"If you enjoy using this app, would you mind taking a moment to invite a few friends that you think will also like it?"
                          delegate:self
                          cancelButtonTitle:@"No Thanks"
                          otherButtonTitles:@"Tell Friends!", @"Remind Me Later", nil];
    [alert show];
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
