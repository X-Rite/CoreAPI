//
//  CAPI.m
//  CoreAPI
//
//  Created by Alexander Cohen on 2016-11-06.
//  Copyright © 2016 X-Rite, Inc. All rights reserved.
//

#import "CAPI.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

NSString* const CAPIUseContentTypeSerializer = @"useContentTypeSerializer";
NSString* const CAPIUseDefaultValidation = @"useDefaultValidation";
NSString* const CAPINetworkServiceType = @"networkServiceType";
NSString* const CAPICachePolicy = @"cachePolicy";
NSString* const CAPIAllowsCellularAccess = @"allowsCellularAccess";
NSString* const CAPIHTTPShouldUsePipelining = @"HTTPShouldUsePipelining";

/**
 * CAPI with: config
 * mostly directly related to NSURLSessionConfiguration
 */
NSString* const CAPIBaseURL = @"baseURL";
NSString* const CAPITimeoutIntervalForRequest = @"timeoutIntervalForRequest";
NSString* const CAPITimeoutIntervalForResource = @"timeoutIntervalForResource";
NSString* const CAPIDiscretionary = @"discretionary";
NSString* const CAPISharedContainerIdentifier = @"sharedContainerIdentifier";
NSString* const CAPISessionSendsLaunchEvents = @"sessionSendsLaunchEvents";
NSString* const CAPIConnectionProxyDictionary = @"connectionProxyDictionary";
NSString* const CAPITLSMinimumSupportedProtocol = @"TLSMinimumSupportedProtocol";
NSString* const CAPITLSMaximumSupportedProtocol = @"TLSMaximumSupportedProtocol";
NSString* const CAPIHTTPShouldSetCookies = @"HTTPShouldSetCookies";
NSString* const CAPIHTTPCookieAcceptPolicy = @"HTTPCookieAcceptPolicy";
NSString* const CAPIHTTPAdditionalHeaders = @"HTTPAdditionalHeaders";
NSString* const CAPIHTTPMaximumConnectionsPerHost = @"HTTPMaximumConnectionsPerHost";
NSString* const CAPIHTTPCookieStorage = @"HTTPCookieStorage";
NSString* const CAPIURLCredentialStorage = @"URLCredentialStorage";
NSString* const CAPIURLCache = @"URLCache";
NSString* const CAPIShouldUseExtendedBackgroundIdleMode = @"shouldUseExtendedBackgroundIdleMode";
NSString* const CAPIProtocolClasses = @"protocolClasses";

/**
 * CAPI Request config
 */
NSString* const CAPIURL = @"URL";
NSString* const CAPIParams = @"params";
NSString* const CAPIMethod = @"method";
NSString* const CAPIData = @"data";
NSString* const CAPIHTTPShouldHandleCookies = @"HTTPShouldHandleCookies";
NSString* const CAPIHeaders = @"headers";

NSString* const CAPIErrorDomain = @"CAPIErrorDomain";

typedef void(^CAPIRequestEmptyCompletion)( id obj, ... );

@interface CAPIResponse ()

@property (nonatomic,strong) NSURLRequest* request;

@property (nonatomic,strong) NSData* data;
@property (nonatomic,strong) NSHTTPURLResponse* httpResponse;
@property (nonatomic,strong) NSError* error;

@property (nonatomic,strong) id body;

@end

@implementation CAPIResponse
@end

@interface CAPITask : NSObject

@property (nonatomic,copy,readonly) NSString* identifier;

@property (nonatomic,copy) NSDictionary* config;
@property (nonatomic,copy) NSURLRequest* request;

@property (nonatomic,strong) NSURLSessionTask* sessionTask;
@property (nonatomic,strong) NSOperationQueue*  queue;

@property (nonatomic,strong) CPPromise* promise;
@property (nonatomic,copy) CPPromiseResolver promiseResolver;

@property (nonatomic,strong) NSMutableArray<CAPIResponseValidate>* validationBlocks;
@property (nonatomic,copy) CAPIResponseSerialize serializeBlock;

@property (nonatomic,strong) CAPIResponse* response;

@end

@implementation CAPITask

- (instancetype)init
{
    self = [super init];
    self.validationBlocks = [NSMutableArray array];
    return self;
}

- (NSString *)identifier
{
    return self.request.URL.absoluteString;
}

@end

static BOOL CAPIIsBlock(id _Nullable block) {
    static Class blockClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blockClass = [^{} class];
        while ([blockClass superclass] != NSObject.class) {
            blockClass = [blockClass superclass];
        }
    });
    
    return [block isKindOfClass:blockClass];
}

enum {
    CTBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    CTBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    CTBlockDescriptionFlagsIsGlobal = (1 << 28),
    CTBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    CTBlockDescriptionFlagsHasSignature = (1 << 30)
};
typedef int CTBlockDescriptionFlags;

struct CTBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

static NSMethodSignature* CAPIMethodSignatureFromBlock(id _Nullable block) {
 
    if ( !CAPIIsBlock(block) )
        return nil;
    
    struct CTBlockLiteral*  blockRef = (__bridge struct CTBlockLiteral *)block;
    CTBlockDescriptionFlags flags = blockRef->flags;
    //unsigned long int       size = blockRef->descriptor->size;
    
    if (flags & CTBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (flags & CTBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    
    return nil;
}

@interface NSDictionary (CAPI)

- (NSURL*)capi_urlForKey:(NSString*)key;

@end

@implementation NSDictionary (CAPI)

- (NSURL *)capi_urlForKey:(NSString *)key
{
    id val = self[key];
    if ( !val )
        return nil;
    if ( [val isKindOfClass:[NSURL class]] )
        return val;
    if ( [val isKindOfClass:[NSString class]] )
        return [NSURL URLWithString:val];
    return nil;
}

@end

@interface CAPI ()

@property (nonatomic,copy) NSDictionary* config;
- (instancetype)initWithConfig:(NSDictionary*)config;

@property (nonatomic,strong) NSURLSession* session;

@end

@implementation CAPI

+ (instancetype)with:(NSDictionary *)config
{
    return [[[self class] alloc] initWithConfig:config];
}

- (instancetype)initWithConfig:(NSDictionary*)config
{
    self = [super init];
    self.config = [config copy];
    return self;
}

- (NSURLSessionConfiguration*)_sessionConfigurationFromConfig:(NSDictionary*)config
{
    NSURLSessionConfiguration* sessionConfig = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
    
    if ( config[CAPICachePolicy] )
        sessionConfig.requestCachePolicy = [config[CAPICachePolicy] integerValue];
    
    if ( config[CAPITimeoutIntervalForRequest] )
        sessionConfig.requestCachePolicy = [config[CAPITimeoutIntervalForRequest] doubleValue];
    
    if ( config[CAPITimeoutIntervalForResource] )
        sessionConfig.requestCachePolicy = [config[CAPITimeoutIntervalForResource] doubleValue];
    
    if ( config[CAPINetworkServiceType] )
        sessionConfig.networkServiceType = [config[CAPINetworkServiceType] integerValue];
    
    if ( config[CAPIAllowsCellularAccess] )
        sessionConfig.allowsCellularAccess = [config[CAPIAllowsCellularAccess] boolValue];
    
    if ( config[CAPIDiscretionary] )
        sessionConfig.discretionary = [config[CAPIDiscretionary] boolValue];
    
    if ( config[CAPISharedContainerIdentifier] )
        sessionConfig.sharedContainerIdentifier = config[CAPISharedContainerIdentifier];
    
    if ( config[CAPISessionSendsLaunchEvents] )
        sessionConfig.requestCachePolicy = [config[CAPISessionSendsLaunchEvents] boolValue];
    
    if ( config[CAPIConnectionProxyDictionary] )
        sessionConfig.connectionProxyDictionary = config[CAPIConnectionProxyDictionary];
    
    if ( config[CAPITLSMinimumSupportedProtocol] )
        sessionConfig.TLSMinimumSupportedProtocol = [config[CAPITLSMinimumSupportedProtocol] intValue];
    
    if ( config[CAPITLSMaximumSupportedProtocol] )
        sessionConfig.TLSMaximumSupportedProtocol = [config[CAPITLSMaximumSupportedProtocol] intValue];
    
    if ( config[CAPIHTTPShouldUsePipelining] )
        sessionConfig.HTTPShouldUsePipelining = [config[CAPIHTTPShouldUsePipelining] boolValue];
    
    if ( config[CAPIHTTPShouldSetCookies] )
        sessionConfig.HTTPShouldSetCookies = [config[CAPIHTTPShouldSetCookies] boolValue];
    
    if ( config[CAPIHTTPCookieAcceptPolicy] )
        sessionConfig.HTTPCookieAcceptPolicy = [config[CAPIHTTPCookieAcceptPolicy] integerValue];
    
    if ( config[CAPIHTTPAdditionalHeaders] )
        sessionConfig.HTTPAdditionalHeaders = config[CAPIHTTPAdditionalHeaders];
    
    if ( config[CAPIHTTPMaximumConnectionsPerHost] )
        sessionConfig.HTTPMaximumConnectionsPerHost = [config[CAPIHTTPMaximumConnectionsPerHost] integerValue];
    
    if ( config[CAPIHTTPCookieStorage] )
        sessionConfig.HTTPCookieStorage = config[CAPIHTTPCookieStorage];
    
    if ( config[CAPIURLCredentialStorage] )
        sessionConfig.URLCredentialStorage = config[CAPIURLCredentialStorage];
    
    if ( config[CAPIURLCache] )
        sessionConfig.URLCache = config[CAPIURLCache];
    
    if ( config[CAPIShouldUseExtendedBackgroundIdleMode] )
        sessionConfig.shouldUseExtendedBackgroundIdleMode = [config[CAPIShouldUseExtendedBackgroundIdleMode] boolValue];
    
    if ( config[CAPIProtocolClasses] )
        sessionConfig.protocolClasses = config[CAPIProtocolClasses];
    
    return sessionConfig;
}

- (void)_setupSession
{
    NSURLSessionConfiguration* sessionConfiguration = [self _sessionConfigurationFromConfig:self.config];
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
}

- (void)setConfig:(NSDictionary *)config
{
    _config = [config copy];
    [self _setupSession];
}

- (NSURLRequest*)_requestFromConfig:(NSDictionary*)config
{
    NSMutableURLRequest*    req = nil;
    NSURLComponents*        urlComponents = nil;
    NSURL*                  baseURL = [self.config capi_urlForKey:CAPIBaseURL];
    NSURL*                  URL = nil;
    
    if ( [config capi_urlForKey:CAPIBaseURL] )
        baseURL = [config capi_urlForKey:CAPIBaseURL];
    URL = [config capi_urlForKey:CAPIURL];
    if ( baseURL && URL )
           URL = [[NSURL alloc] initWithString:URL.absoluteString relativeToURL:baseURL];
    req = [NSMutableURLRequest requestWithURL:URL];

    urlComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    NSMutableArray<NSURLQueryItem*>* queryItems = [urlComponents.queryItems mutableCopy];
    NSDictionary<NSString*,NSString*>* params = config[CAPIParams];
    if ( params.count )
    {
        if ( !queryItems )
            queryItems = [NSMutableArray array];
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
        }];
        
        urlComponents.queryItems = [queryItems copy];
        
    }
    URL = [urlComponents URL];
    
    if ( URL )
        req.URL = URL;

    if ( config[CAPICachePolicy] )
        req.cachePolicy = [config[CAPICachePolicy] integerValue];
    
    if ( config[CAPINetworkServiceType] )
        req.networkServiceType = [config[CAPINetworkServiceType] integerValue];
    
    if ( config[CAPIAllowsCellularAccess] )
        req.allowsCellularAccess = [config[CAPIAllowsCellularAccess] boolValue];
    
    if ( config[CAPIMethod] )
        req.HTTPMethod = config[CAPIMethod];
    
    id data = config[CAPIData];
    if ( [data isKindOfClass:[NSData class]] )
        req.HTTPBody = data;
    else if ( [data isKindOfClass:[NSDictionary class]] )
        req.HTTPBody = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    else if ( [data isKindOfClass:[NSString class]] )
        req.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    if ( config[CAPIHTTPShouldHandleCookies] )
        req.HTTPShouldHandleCookies = [config[CAPIHTTPShouldHandleCookies] boolValue];
    
    if ( config[CAPIHTTPShouldUsePipelining] )
        req.HTTPShouldUsePipelining = [config[CAPIHTTPShouldUsePipelining] boolValue];
    
    [(NSDictionary*)config[CAPIHeaders] enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSString*  _Nonnull obj, BOOL * _Nonnull stop) {
        [req addValue:obj forHTTPHeaderField:key];
    }];

    return req;
}

+ (NSCache*)_taskCache
{
    static NSCache* cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.name = @"com.bedroomcode.capi.task.cache";
    });
    return cache;
}

+ (void)_cacheTask:(CAPITask*)task
{
    if ( [task.request.HTTPMethod compare:@"get" options:NSCaseInsensitiveSearch] != NSOrderedSame )
        return;
    [[self _taskCache] setObject:task forKey:task.identifier];
}

+ (void)_uncacheTask:(CAPITask*)task
{
    if ( [task.request.HTTPMethod compare:@"get" options:NSCaseInsensitiveSearch] != NSOrderedSame )
        return;
    [[self _taskCache] removeObjectForKey:task.identifier];
}

+ (CAPITask*)_existingTaskForRequest:(NSURLRequest*)request
{
    return [[self _taskCache] objectForKey:request.URL.absoluteString];
}

- (void)_destroyTask:(CAPITask*)task
{
    [self.class _uncacheTask:task];
    
    task.request = nil;
    task.queue = nil;
    task.response = nil;
    task.sessionTask = nil;
    task.promise = nil;
    task.promiseResolver = nil;
    task.serializeBlock = nil;
    task.validationBlocks = nil;
}

- (void)_finishTask:(CAPITask*)inTask withResponse:(CAPIResponse*)response
{
    void (^finish)( CAPITask* task ) = ^( CAPITask* task ) {
        
        NSArray<CAPIResponseValidate>* validations = [task.validationBlocks copy];
        [validations enumerateObjectsUsingBlock:^(CAPIResponseValidate  _Nonnull handler, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( !handler(task.response.httpResponse) )
            {
                task.response.error = [NSError errorWithDomain:CAPIErrorDomain code:task.response.httpResponse.statusCode userInfo:nil];
                *stop = YES;
            }
        }];
        
        if ( task.serializeBlock && !task.response.error )
            task.response.body = task.serializeBlock( task.response.httpResponse, task.response.data );
        
        if ( task.promiseResolver )
            task.promiseResolver( task.response.error ? task.response.error : task.response );

        [self _destroyTask:task];
    };
    
    inTask.response = response;
    if ( inTask.queue )
        [inTask.queue addOperationWithBlock:^{
            finish(inTask);
        }];
    else
        finish(inTask);
}

- (CPPromise*)_runRequestWithConfig:(id)config overloadConfigs:(NSDictionary*)overloadConfigs args:(va_list)args
{
    NSMutableDictionary* fullConfig = [NSMutableDictionary dictionary];
    
    // add defaults
    fullConfig[CAPIUseContentTypeSerializer] = @(YES);
    fullConfig[CAPIUseDefaultValidation] = @(YES);
    
    // pull the rest from configs
    if ( [config isKindOfClass:[NSString class]] || [config isKindOfClass:[NSURL class]] )
        fullConfig[CAPIURL] = config;
    else if ( [config isKindOfClass:[NSDictionary class]] )
        [fullConfig addEntriesFromDictionary:config];

    CAPITask* task = [CAPITask new];
    task.config = fullConfig;
    
    // loop args
    while (1)
    {
        id val = va_arg(args, id);
        if ( !val )
            break;
        
        if ( [val isKindOfClass:[NSDictionary class]] )
            [fullConfig addEntriesFromDictionary:val];
        else if ( [val isKindOfClass:[NSOperationQueue class]] )
            task.queue = val;
        else if ( CAPIIsBlock(val) )
        {
            NSMethodSignature*  sig = CAPIMethodSignatureFromBlock(val);
            if ( sig )
            {
                const char  rtype = sig.methodReturnType[0];
                if ( sig.numberOfArguments == 2 )
                {
                    if ( rtype == 'B' || rtype == 'c' )
                    {
                        [task.validationBlocks addObject:[val copy]];
                    }
                    else
                        break;
                }
                else if ( sig.numberOfArguments == 3 )
                {
                    if ( rtype == '@' )
                    {
                        task.serializeBlock = [val copy];
                    }
                    else
                        break;
                }
            }
        }
    }
    
    
    // overload config
    if ( overloadConfigs )
        [fullConfig addEntriesFromDictionary:overloadConfigs];
    
    // make the request
    task.request = [self _requestFromConfig:fullConfig];
    
    // check for an existing request
    CAPITask* cachedTask = [self.class _existingTaskForRequest:task.request];
    if ( cachedTask )
    {
        // kill the old task
        [self _destroyTask:task];
        task = nil;
        
        // return the cache task promise to the user
        return cachedTask.promise;
    }
    
    // create a new task promise
    task.promise = [CPPromise promiseWithResolverBlock:^(CPPromiseResolver  _Nonnull resolver) {
        task.promiseResolver = resolver;
    }];
    
    // cache this task
    [self.class _cacheTask:task];
    
    // validation
    if ( [self.config[CAPIUseDefaultValidation] boolValue] || [fullConfig[CAPIUseDefaultValidation] boolValue] )
    {
        [task.validationBlocks insertObject:^BOOL(NSHTTPURLResponse* response) {
            return response.statusCode >= 200 && response.statusCode < 400; // sould this be 300 ??
        } atIndex:0];
    }
    
    //serialization
    if ( !task.serializeBlock && ( [self.config[CAPIUseContentTypeSerializer] boolValue] || [fullConfig[CAPIUseContentTypeSerializer] boolValue] ) )
    {
        task.serializeBlock = ^id( NSHTTPURLResponse* response, NSData* data ) {
          
            NSString*           contentType = [[response allHeaderFields][@"Content-Type"] componentsSeparatedByString:@";"].firstObject;
            NSArray<NSString*>* types = [contentType componentsSeparatedByString:@"/"];
            
            if ( types.count != 2 )
                return data;
            
            NSString* part1 = types.firstObject;
            NSString* part2 = types.lastObject;
            
            if ( [part1 isEqualToString:@"text"] )
            {
                return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
            }
            else if ( [part1 isEqualToString:@"image"] )
            {
#if TARGET_OS_IOS
                return data ? [UIImage imageWithData:data] : nil;
#else
                return data ? [[NSImage alloc] initWithData:data] : nil;
#endif
            }
            else if ( [part1 isEqualToString:@"application"] )
            {
                if ( [part2 isEqualToString:@"json"] )
                {
                    NSDictionary* json = nil;
                    @try {
                        json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                    } @catch (NSException *exception) {
                        json = nil;
                    }
                    return json;
                }
            }
            
            return data;
            
        };
    }

    task.sessionTask = [self.session dataTaskWithRequest:task.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        CAPIResponse* rsp = [CAPIResponse new];
        rsp.request = task.request;
        rsp.data = data;
        rsp.httpResponse = (NSHTTPURLResponse*)response;
        rsp.error = error;
        
        [self _finishTask:task withResponse:rsp];
        
    }];
    [task.sessionTask resume];
    
    return task.promise;
}

- (CAPIRequestBlock)request
{
    return ^CPPromise*( id config, ... ) NS_REQUIRES_NIL_TERMINATION {
        CPPromise* promise = nil;
        va_list args;
        va_start(args, config);
        promise = [self _runRequestWithConfig:config overloadConfigs:nil args:args];
        va_end(args);
        return promise;
    };
}

- (CAPIRequestBlock)GET
{
    return ^CPPromise*( id config, ... ) NS_REQUIRES_NIL_TERMINATION {
        CPPromise* promise = nil;
        va_list args;
        va_start(args, config);
        promise = [self _runRequestWithConfig:config overloadConfigs:@{ CAPIMethod : @"GET" } args:args];
        va_end(args);
        return promise;
    };
}

- (CAPIRequestBlock)POST
{
    return ^CPPromise*( id config, ... ) NS_REQUIRES_NIL_TERMINATION {
        CPPromise* promise = nil;
        va_list args;
        va_start(args, config);
        promise = [self _runRequestWithConfig:config overloadConfigs:@{ CAPIMethod : @"POST" } args:args];
        va_end(args);
        return promise;
    };
}

@end









