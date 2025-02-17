#import "BTVenmoAppSwitchRequestURL.h"

// MARK: - Swift File Imports for Package Managers
#if __has_include(<Braintree/Braintree-Swift.h>) // CocoaPods
#import <Braintree/Braintree-Swift.h>

#elif SWIFT_PACKAGE                              // SPM
/* Use @import for SPM support
 * See https://forums.swift.org/t/using-a-swift-package-in-a-mixed-swift-and-objective-c-project/27348
 */
@import BraintreeCore;

#elif __has_include("Braintree-Swift.h")         // CocoaPods for ReactNative
/* Use quoted style when importing Swift headers for ReactNative support
 * See https://github.com/braintree/braintree_ios/issues/671
 */
#import "Braintree-Swift.h"

#else                                            // Carthage
#import <BraintreeCore/BraintreeCore-Swift.h>
#endif

#define kXCallbackTemplate @"scheme://x-callback-url/path"
#define kVenmoScheme @"com.venmo.touch.v2"

@implementation BTVenmoAppSwitchRequestURL

+ (NSURL *)baseAppSwitchURL {
    return [self appSwitchBaseURLComponents].URL;
}

+(NSURL *)appSwitchURLForMerchantID:(NSString *)merchantID
                        accessToken:(NSString *)accessToken
                    returnURLScheme:(NSString *)scheme
                  bundleDisplayName:(NSString *)bundleName
                        environment:(NSString *)environment
                   paymentContextID:(NSString *)paymentContextID
                           metadata:(BTClientMetadata *)metadata
{
    NSURL *successReturnURL = [self returnURLWithScheme:scheme result:@"success"];
    NSURL *errorReturnURL = [self returnURLWithScheme:scheme result:@"error"];
    NSURL *cancelReturnURL = [self returnURLWithScheme:scheme result:@"cancel"];
    if (!successReturnURL || !errorReturnURL || !cancelReturnURL || !accessToken || !metadata || !scheme || !bundleName || !environment || !merchantID) {
        return nil;
    }
    
    NSMutableDictionary *braintreeData = [@{@"_meta": @{
                                                    @"version": BTCoreConstants.braintreeSDKVersion,
                                                    @"sessionId": [metadata sessionID],
                                                    @"integration": [metadata integrationString],
                                                    @"platform": @"ios"
                                                    }
                                            } mutableCopy];

    NSData *serializedBraintreeData = [NSJSONSerialization dataWithJSONObject:braintreeData options:0 error:NULL];
    NSString *base64EncodedBraintreeData = [serializedBraintreeData base64EncodedStringWithOptions:0];

    NSMutableDictionary *appSwitchParameters = [@{@"x-success": successReturnURL,
                                                  @"x-error": errorReturnURL,
                                                  @"x-cancel": cancelReturnURL,
                                                  @"x-source": bundleName,
                                                  @"braintree_merchant_id": merchantID,
                                                  @"braintree_access_token": accessToken,
                                                  @"braintree_environment": environment,
                                                  @"braintree_sdk_data": base64EncodedBraintreeData,
                                                  } mutableCopy];

    if (paymentContextID) {
        appSwitchParameters[@"resource_id"] = paymentContextID;
    }

    NSURLComponents *components = [self appSwitchBaseURLComponents];
    components.percentEncodedQuery = [BTURLUtils queryStringWithDictionary:appSwitchParameters];
    return components.URL;
}

#pragma mark Internal Helpers

+ (NSURL *)returnURLWithScheme:(NSString *)scheme result:(NSString *)result {
    NSURLComponents *components = [NSURLComponents componentsWithString:kXCallbackTemplate];
    components.scheme = scheme;
    components.percentEncodedPath = [NSString stringWithFormat:@"/vzero/auth/venmo/%@", result];
    return components.URL;
}

+ (NSURLComponents *)appSwitchBaseURLComponents {
    NSURLComponents *components = [NSURLComponents componentsWithString:kXCallbackTemplate];
    components.scheme = kVenmoScheme;
    components.percentEncodedPath = @"/vzero/auth";
    return components;
}

@end
