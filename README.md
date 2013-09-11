# Facebook SDK 3.5 for iOS - Sample How Tos

Sample apps to support How To documentation found in the iOS Dev Center.

Authors: Christine Abernathy (caabernathy)

## Demo

Nothing yet.

## Installing

Installing the samples requires you to add the Facebook SDK, the Facebook SDK resource bundle, and the Facebook SDK deprecated headers for some samples. The missing required libraries and files will show up in red under the `Frameworks` folder when you open up the project. Simply delete those references then do the following:

* Add the Facebook SDK for iOS Framework by dragging the `FacebookSDK.framework` folder from the SDK installation folder into the Frameworks section of your Project Navigator.

* Choose 'Create groups for any added folders' and deselect 'Copy items into destination group's folder (if needed)' to keep the reference to the SDK installation folder, rather than creating a copy.

* Add the Facebook SDK for iOS resource bundle by dragging the `FacebookSDKResources.bundle` file from the `FacebookSDK.framework/Resources` folder into the Frameworks section of your Project Navigator.

* As you did when copying the Framework, choose 'Create groups for any added folders' and deselect 'Copy items into destination group's folder (if needed)'

* For the How To samples that use the deprecated headers, ex: Send Requests, add the Deprecated Headers. The headers can be found here `~Documents/FacebookSDK/FacebookSDK.framework/Versions/A/DeprecatedHeaders`. Drag the whole DeprecatedHeaders folder and deselect the ''Copy items into destibation group's folder (if needed)'' option to add the headers as a reference.

* Build and run the project.

## Documentation

How Tos section from https://developers.facebook.com/docs/getting-started/getting-started-with-the-ios-sdk/

## Additional Resources

Facebook SDK for iOS documentation can be found at https://developers.facebook.com/ios/

## Contributing

All contributors must agree to and sign the [Facebook CLA](https://developers.facebook.com/opensource/cla) prior to submitting Pull Requests. We cannot accept Pull Requests until this document is signed and submitted.

## License

Copyright 2012-present Facebook, Inc.

You are hereby granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, and distribute this software in source code or binary form for use in connection with the web services and APIs provided by Facebook.

As with any software that integrates with the Facebook platform, your use of this software is subject to the Facebook Developer Principles and Policies [http://developers.facebook.com/policy/]. This copyright notice shall be included in all copies or substantial portions of the software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
