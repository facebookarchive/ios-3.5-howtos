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

#import "MyTokenCachingStrategy.h"

// Local vs. Remote flag
// Set to local initially. You can change to the remote endpoint
// once you've set up your remote token caching endpoint.
static BOOL kLocalCache = YES;

// Local cache - unique file info
static NSString* kFilename = @"TokenInfo.plist";

// Remote cache - backend server
// Replace <YOUR_BACKEND_SERVER> with your token caching endpoint.
// See: https://developers.facebook.com/docs/howtos/token-caching-ios-sdk/
// for more details on setting up the endpoint.
static NSString* kBackendURL = @"<YOUR_BACKEND_SERVER>/token.php";

// Remote cache - date format
static NSString* kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ";

@interface MyTokenCachingStrategy ()
@property (nonatomic, strong) NSString *tokenFilePath;
- (NSString *) filePath;
@end

@implementation MyTokenCachingStrategy

#pragma mark - Initialization methods
/*
 * Init method.
 */
- (id) init
{
    self = [super init];
    if (self) {
        _tokenFilePath = [self filePath];
        _thirdPartySessionId = @"";
    }
    return self;
}

#pragma FBTokenCachingStrategy override methods

/*
 * Override method called to cache token.
 */
- (void)cacheFBAccessTokenData:(FBAccessTokenData *)accessToken
{
    NSDictionary *tokenInformation = [accessToken dictionary];
    if (kLocalCache) {
        [self writeData:tokenInformation];
    } else {
        [self writeDataRemotely:tokenInformation];
    }
}

/*
 * Override method to fetch token.
 */
- (FBAccessTokenData *)fetchFBAccessTokenData
{
    NSDictionary *tokenInformation;
    if (kLocalCache) {
        tokenInformation = [self readData];
    } else {
        tokenInformation = [self readDataRemotely];
    }
    if (nil == tokenInformation) {
        return nil;
    } else {
        return [FBAccessTokenData createTokenFromDictionary:tokenInformation];
    }
}

/*
 * Override method to clear token.
 */
- (void)clearToken
{
    if (kLocalCache) {
        [self writeData:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
    } else {
        [self writeDataRemotely:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
    }
}

#pragma mark - Local caching helper methods

/*
 * Helper method to get the local file path.
 */
- (NSString *) filePath {
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    return [documentsDirectory stringByAppendingPathComponent:kFilename];
}

/*
 * Helper method to write data.
 */
- (void) writeData:(NSDictionary *) data {
    NSLog(@"File = %@ and Data = %@", self.tokenFilePath, data);
    BOOL success = [data writeToFile:self.tokenFilePath atomically:YES];
    if (!success) {
        NSLog(@"Error writing to file");
    }
}

/*
 * Helper method to read data.
 */
- (NSDictionary *) readData {
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:self.tokenFilePath];
    NSLog(@"File = %@ and data = %@", self.tokenFilePath, data);
    return data;
}


#pragma mark - Remote caching helper methods

/*
 * Helper method to look for strings that represent dates and
 * convert them to NSDate objects.
 */
- (NSMutableDictionary *) dictionaryDateParse: (NSDictionary *) data {
    // Date format for date checks
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    // Dictionary to return
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    // Enumerate through the input dictionary
    [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // Check if strings are dates
        if ([obj isKindOfClass:[NSString class]]) {
            NSDate *objDate = nil;
            BOOL isDate = [dateFormatter getObjectValue:&objDate
                                              forString:obj
                                       errorDescription:nil];
            if (isDate) {
                resultDictionary[key] = objDate;
                [resultDictionary setObject:objDate forKey:key];
            } else {
                resultDictionary[key] = obj;
            }
        } else {
            // Non-string, just keep as-is
            resultDictionary[key] = obj;
        }
    }];
    return resultDictionary;
}

/*
 * Helper method to check the back-end server response
 * for both reads and writes.
 */
- (NSDictionary *) handleResponse:(NSData *)responseData {
    NSError *jsonError = nil;
    id result = [NSJSONSerialization JSONObjectWithData:responseData
                                                options:0
                                                  error:&jsonError];
    if (jsonError) {
        return nil;
    }
    // Check for a properly formatted response
    if ([result isKindOfClass:[NSDictionary class]] &&
        result[@"status"]) {
        // Check if we got a success case back
        BOOL success = [result[@"status"] boolValue];
        if (!success) {
            // Handle the error case
            NSLog(@"Error: %@", result[@"errorMessage"]);
            return nil;
        } else {
            // Check for returned token data (in the case of read requests)
            if (result[@"token_info"]) {
                // Create an NSDictionary of the token data
                NSData *jsonData = [result[@"token_info"]
                                    dataUsingEncoding:NSUTF8StringEncoding];
                if (jsonData) {
                    jsonError = nil;
                    NSDictionary *tokenResult =
                    [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:&jsonError];
                    if (jsonError) {
                        return nil;
                    }
                    
                    // Check if valid data returned, i.e. not nil
                    if ([tokenResult isKindOfClass:[NSDictionary class]]) {
                        // Parse the results to handle conversion for
                        // date values.
                        return [self dictionaryDateParse:tokenResult];
                    } else {
                        return nil;
                    }
                } else {
                    return nil;
                }
            } else {
                return nil;
            }
        }
    } else {
        NSLog(@"Error, did not get any data back");
        return nil;
    }
}

/*
 * Helper method to write data.
 */
- (void) writeDataRemotely:(NSDictionary *) data {
    NSLog(@"Write - Data = %@", data);
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    NSError *error = nil;
    NSString *jsonDataString = @"";
    if (nil != data) {
        NSMutableDictionary *copyData = [data mutableCopy];
        // Enumerate through the input dictionary
        [data enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
            if([object isKindOfClass:[NSDate class]]) {
                copyData[key] = [dateFormatter stringFromDate:object];
            } else {
                copyData[key] = object;
            }
        }];
        NSData *jsonData = [NSJSONSerialization
                            dataWithJSONObject:copyData
                            options:0
                            error:&error];
        if (error) {
            NSLog(@"JSON error: %@", error);
            return;
        }
        jsonDataString = [[NSString alloc] initWithData:jsonData
                                               encoding:NSUTF8StringEncoding];
    }
    
    NSURLResponse *response = nil;
    error = nil;
    // Set up a URL request to the back-end server
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:
                                       [NSURL URLWithString:kBackendURL]];
    // Configure an HTTP POST
    [urlRequest setHTTPMethod:@"POST"];
    // Pass in post data: the unique ID and the JSON string
    // representation of the token data.
    NSString *postData = [NSString stringWithFormat:@"unique_id=%@&token_info=%@",
                          self.thirdPartySessionId,jsonDataString];
    [urlRequest setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    // Make a synchronous request
    NSData *responseData = (NSMutableData *)[NSURLConnection
                                             sendSynchronousRequest:urlRequest
                                             returningResponse:&response
                                             error:&error];
    // Process the returned data
    [self handleResponse:responseData];
}

/*
 * Helper method to read data.
 */
- (NSDictionary *) readDataRemotely {
    NSURLResponse *response = nil;
    NSError *error = nil;
    // Set up a URL request to the back-end server, a
    // GET request with the unique ID passed in.
    NSString *urlString = [NSString stringWithFormat:@"%@?unique_id=%@",
                           kBackendURL, self.thirdPartySessionId];
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:
                                [NSURL URLWithString:urlString]];
    // Make a synchronous request
    NSData *responseData = (NSMutableData *)[NSURLConnection
                                             sendSynchronousRequest:urlRequest
                                             returningResponse:&response
                                             error:&error];
    if (nil != responseData) {
        // Process the returned data
        return [self handleResponse:responseData];
    } else {
        return nil;
    }
}

@end
