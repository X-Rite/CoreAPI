//
//  CAPI.h
//  CoreAPI
//
//  Created by Alexander Cohen on 2016-11-06.
//  Copyright © 2016 X-Rite, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePromise/CorePromise.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const CAPIErrorDomain;

/**
 * CAPI with:config or request: config
 */
extern NSString* const CAPIUseContentTypeSerializer;
extern NSString* const CAPIUseDefaultValidation;
extern NSString* const CAPINetworkServiceType;
extern NSString* const CAPICachePolicy;
extern NSString* const CAPIAllowsCellularAccess;
extern NSString* const CAPIHTTPShouldUsePipelining;

/**
 * CAPI with: config
 * mostly directly related to NSURLSessionConfiguration
 */
extern NSString* const CAPIBaseURL;
extern NSString* const CAPITimeoutIntervalForRequest;
extern NSString* const CAPITimeoutIntervalForResource;
extern NSString* const CAPIDiscretionary;
extern NSString* const CAPISharedContainerIdentifier;
extern NSString* const CAPISessionSendsLaunchEvents;
extern NSString* const CAPIConnectionProxyDictionary;
extern NSString* const CAPITLSMinimumSupportedProtocol;
extern NSString* const CAPITLSMaximumSupportedProtocol;
extern NSString* const CAPIHTTPShouldSetCookies;
extern NSString* const CAPIHTTPCookieAcceptPolicy;
extern NSString* const CAPIHTTPAdditionalHeaders;
extern NSString* const CAPIHTTPMaximumConnectionsPerHost;
extern NSString* const CAPIHTTPCookieStorage;
extern NSString* const CAPIURLCredentialStorage;
extern NSString* const CAPIURLCache;
extern NSString* const CAPIShouldUseExtendedBackgroundIdleMode;
extern NSString* const CAPIProtocolClasses;

/**
 * CAPI Request config
 */
extern NSString* const CAPIURL;
extern NSString* const CAPIParams;
extern NSString* const CAPIMethod;
extern NSString* const CAPIData;
extern NSString* const CAPIHTTPShouldHandleCookies;
extern NSString* const CAPIHeaders;

/**
 * CAPI Response object
 */
NS_CLASS_AVAILABLE(10_11,9_0) @interface CAPIResponse : NSObject

@property (nonatomic,readonly) NSURLRequest* request;

@property (nonatomic,readonly) NSData* data;
@property (nonatomic,readonly) NSHTTPURLResponse* httpResponse;
@property (nonatomic,readonly) NSError* error;

@property (nonatomic,readonly) id body;

@end

typedef id _Nullable(^CAPIResponseSerialize)( NSHTTPURLResponse* httpResponse, NSData* data );
typedef BOOL(^CAPIResponseValidate)( NSHTTPURLResponse* httpResponse );
typedef CPPromise<CAPIResponse*>* _Nonnull(^CAPIRequestBlock)( id config, ... ); // requires nil terminator

NS_CLASS_AVAILABLE(10_11,9_0) @interface CAPI : NSObject

+ (instancetype)with:(NSDictionary*)config;

@property (nonatomic,copy,readonly) CAPIRequestBlock request;
@property (nonatomic,copy,readonly) CAPIRequestBlock GET;
@property (nonatomic,copy,readonly) CAPIRequestBlock POST;

@end

NS_ASSUME_NONNULL_END
