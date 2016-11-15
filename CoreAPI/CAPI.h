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

#ifdef __cplusplus
#define CAPI_EXTERN    extern "C" __attribute__((visibility ("default")))
#else
#define CAPI_EXTERN    extern __attribute__((visibility ("default")))
#endif

CAPI_EXTERN NSString* const CAPIErrorDomain;

/**
 * CAPI with:config or request: config
 */
CAPI_EXTERN NSString* const CAPIUseContentTypeSerializer;
CAPI_EXTERN NSString* const CAPIUseDefaultValidation;
CAPI_EXTERN NSString* const CAPINetworkServiceType;
CAPI_EXTERN NSString* const CAPICachePolicy;
CAPI_EXTERN NSString* const CAPIAllowsCellularAccess;
CAPI_EXTERN NSString* const CAPIHTTPShouldUsePipelining;

/**
 * CAPI with: config
 * mostly directly related to NSURLSessionConfiguration
 */
CAPI_EXTERN NSString* const CAPIBaseURL;
CAPI_EXTERN NSString* const CAPITimeoutIntervalForRequest;
CAPI_EXTERN NSString* const CAPITimeoutIntervalForResource;
CAPI_EXTERN NSString* const CAPIDiscretionary;
CAPI_EXTERN NSString* const CAPISharedContainerIdentifier;
CAPI_EXTERN NSString* const CAPISessionSendsLaunchEvents;
CAPI_EXTERN NSString* const CAPIConnectionProxyDictionary;
CAPI_EXTERN NSString* const CAPITLSMinimumSupportedProtocol;
CAPI_EXTERN NSString* const CAPITLSMaximumSupportedProtocol;
CAPI_EXTERN NSString* const CAPIHTTPShouldSetCookies;
CAPI_EXTERN NSString* const CAPIHTTPCookieAcceptPolicy;
CAPI_EXTERN NSString* const CAPIHTTPAdditionalHeaders;
CAPI_EXTERN NSString* const CAPIHTTPMaximumConnectionsPerHost;
CAPI_EXTERN NSString* const CAPIHTTPCookieStorage;
CAPI_EXTERN NSString* const CAPIURLCredentialStorage;
CAPI_EXTERN NSString* const CAPIURLCache;
CAPI_EXTERN NSString* const CAPIShouldUseExtendedBackgroundIdleMode;
CAPI_EXTERN NSString* const CAPIProtocolClasses;

/**
 * CAPI Request config
 */
CAPI_EXTERN NSString* const CAPIURL;
CAPI_EXTERN NSString* const CAPIParams;
CAPI_EXTERN NSString* const CAPIMethod;
CAPI_EXTERN NSString* const CAPIData;
CAPI_EXTERN NSString* const CAPIHTTPShouldHandleCookies;
CAPI_EXTERN NSString* const CAPIHeaders;

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
