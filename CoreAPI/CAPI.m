//
//  CAPI.m
//  CoreAPI
//
//  Created by Alexander Cohen on 2016-11-06.
//  Copyright © 2016 X-Rite, Inc. All rights reserved.
//

#import "CAPI.h"

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

@property (nonatomic,copy) NSDictionary* config;
@property (nonatomic,copy) NSURLRequest* request;

@property (nonatomic,strong) NSURLSessionTask* sessionTask;
@property (nonatomic,strong) NSOperationQueue*  queue;

@property (nonatomic,strong) NSMutableArray<CAPIResponseValidate>* validationBlocks;
@property (nonatomic,copy) CAPIResponseSerialize serializeBlock;
@property (nonatomic,copy) CAPIRequestEmptyCompletion completionBlock;

@property (nonatomic,strong) CAPIResponse* response;

@end

@implementation CAPITask

- (instancetype)init
{
    self = [super init];
    self.validationBlocks = [NSMutableArray array];
    return self;
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

+ (instancetype)instanceWithConfig:(NSDictionary *)config
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
    
    if ( config[@"requestCachePolicy"] )
        sessionConfig.requestCachePolicy = [config[@"requestCachePolicy"] integerValue];
    
    if ( config[@"timeoutIntervalForRequest"] )
        sessionConfig.requestCachePolicy = [config[@"timeoutIntervalForRequest"] doubleValue];
    
    if ( config[@"timeoutIntervalForResource"] )
        sessionConfig.requestCachePolicy = [config[@"timeoutIntervalForResource"] doubleValue];
    
    if ( config[@"networkServiceType"] )
        sessionConfig.networkServiceType = [config[@"networkServiceType"] integerValue];
    
    if ( config[@"allowsCellularAccess"] )
        sessionConfig.allowsCellularAccess = [config[@"allowsCellularAccess"] boolValue];
    
    if ( config[@"discretionary"] )
        sessionConfig.discretionary = [config[@"discretionary"] boolValue];
    
    if ( config[@"sharedContainerIdentifier"] )
        sessionConfig.sharedContainerIdentifier = config[@"sharedContainerIdentifier"];
    
    if ( config[@"sessionSendsLaunchEvents"] )
        sessionConfig.requestCachePolicy = [config[@"sessionSendsLaunchEvents"] boolValue];
    
    if ( config[@"connectionProxyDictionary"] )
        sessionConfig.connectionProxyDictionary = config[@"connectionProxyDictionary"];
    
    if ( config[@"TLSMinimumSupportedProtocol"] )
        sessionConfig.TLSMinimumSupportedProtocol = [config[@"TLSMinimumSupportedProtocol"] intValue];
    
    if ( config[@"TLSMaximumSupportedProtocol"] )
        sessionConfig.TLSMaximumSupportedProtocol = [config[@"TLSMaximumSupportedProtocol"] intValue];
    
    if ( config[@"HTTPShouldUsePipelining"] )
        sessionConfig.HTTPShouldUsePipelining = [config[@"HTTPShouldUsePipelining"] boolValue];
    
    if ( config[@"HTTPShouldSetCookies"] )
        sessionConfig.HTTPShouldSetCookies = [config[@"HTTPShouldSetCookies"] boolValue];
    
    if ( config[@"HTTPCookieAcceptPolicy"] )
        sessionConfig.HTTPCookieAcceptPolicy = [config[@"HTTPCookieAcceptPolicy"] integerValue];
    
    if ( config[@"HTTPAdditionalHeaders"] )
        sessionConfig.HTTPAdditionalHeaders = config[@"HTTPAdditionalHeaders"];
    
    if ( config[@"HTTPMaximumConnectionsPerHost"] )
        sessionConfig.HTTPMaximumConnectionsPerHost = [config[@"HTTPMaximumConnectionsPerHost"] integerValue];
    
    if ( config[@"HTTPCookieStorage"] )
        sessionConfig.HTTPCookieStorage = config[@"HTTPCookieStorage"];
    
    if ( config[@"URLCredentialStorage"] )
        sessionConfig.URLCredentialStorage = config[@"URLCredentialStorage"];
    
    if ( config[@"URLCache"] )
        sessionConfig.URLCache = config[@"URLCache"];
    
    if ( config[@"shouldUseExtendedBackgroundIdleMode"] )
        sessionConfig.shouldUseExtendedBackgroundIdleMode = [config[@"shouldUseExtendedBackgroundIdleMode"] boolValue];
    
    if ( config[@"protocolClasses"] )
        sessionConfig.protocolClasses = config[@"protocolClasses"];
    
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
    NSURL*                  baseURL = [self.config capi_urlForKey:@"baseURL"];
    NSURL*                  URL = nil;
    
    if ( [config capi_urlForKey:@"baseURL"] )
        baseURL = [config capi_urlForKey:@"baseURL"];
    URL = [config capi_urlForKey:@"URL"];
    if ( baseURL && URL )
           URL = [[NSURL alloc] initWithString:URL.absoluteString relativeToURL:baseURL];
    req = [NSMutableURLRequest requestWithURL:URL];

    urlComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    NSMutableArray<NSURLQueryItem*>* queryItems = [urlComponents.queryItems mutableCopy];
    NSDictionary<NSString*,NSString*>* params = config[@"params"];
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

    if ( config[@"cachePolicy"] )
        req.cachePolicy = [config[@"cachePolicy"] integerValue];
    
    if ( config[@"networkServiceType"] )
        req.networkServiceType = [config[@"networkServiceType"] integerValue];
    
    if ( config[@"allowsCellularAccess"] )
        req.allowsCellularAccess = [config[@"allowsCellularAccess"] boolValue];
    
    if ( config[@"method"] )
        req.HTTPMethod = config[@"method"];
    
    id data = config[@"data"];
    if ( [data isKindOfClass:[NSData class]] )
        req.HTTPBody = data;
    else if ( [data isKindOfClass:[NSDictionary class]] )
        req.HTTPBody = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    else if ( [data isKindOfClass:[NSString class]] )
        req.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    if ( config[@"HTTPShouldHandleCookies"] )
        req.HTTPShouldHandleCookies = [config[@"HTTPShouldHandleCookies"] boolValue];
    
    if ( config[@"HTTPShouldUsePipelining"] )
        req.HTTPShouldUsePipelining = [config[@"HTTPShouldUsePipelining"] boolValue];
    
    [(NSDictionary*)config[@"headers"] enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSString*  _Nonnull obj, BOOL * _Nonnull stop) {
        [req addValue:obj forHTTPHeaderField:key];
    }];

    if ( config[@"cachePolicy"] )
        req.cachePolicy = [config[@"cachePolicy"] integerValue];
    
    if ( config[@"cachePolicy"] )
        req.cachePolicy = [config[@"cachePolicy"] integerValue];
    
    if ( config[@"cachePolicy"] )
        req.cachePolicy = [config[@"cachePolicy"] integerValue];
    
    return req;
}

- (void)_destroyTask:(CAPITask*)task
{
    task.queue = nil;
    task.response = nil;
    task.sessionTask = nil;
    task.completionBlock = nil;
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
        
        if ( task.completionBlock )
            task.completionBlock( response );
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

- (void)_runRequestWithConfig:(id)config overloadConfigs:(NSDictionary*)overloadConfigs args:(va_list)args
{
    NSMutableDictionary* fullConfig = [NSMutableDictionary dictionary];
    
    if ( [config isKindOfClass:[NSString class]] || [config isKindOfClass:[NSURL class]] )
        fullConfig[@"URL"] = config;
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
                    else if ( rtype == 'v' )
                    {
                        task.completionBlock = [val copy];
                        break;
                    }
                }
                else if ( sig.numberOfArguments == 3 )
                {
                    if ( rtype == '@' )
                    {
                        task.serializeBlock = [val copy];
                    }
                }
            }
        }
    }
    
    
    // overload config
    if ( overloadConfigs )
        [fullConfig addEntriesFromDictionary:overloadConfigs];

    task.request = [self _requestFromConfig:fullConfig];
    
    // validation
    if ( [self.config[@"useDefaultValidation"] boolValue] || [fullConfig[@"useDefaultValidation"] boolValue] )
    {
        [task.validationBlocks insertObject:^BOOL(NSHTTPURLResponse* response) {
            return response.statusCode >= 200 && response.statusCode < 300;
        } atIndex:0];
    }
    
    //serialization
    if ( !task.serializeBlock && ( [self.config[@"useContentTypeSerializer"] boolValue] || [fullConfig[@"useContentTypeSerializer"] boolValue] ) )
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
                return data ? [UIImage imageWithData:data] : nil;
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
}

- (CAPIRequestBlock)request
{
    return ^( id config, ... ) {
        va_list args;
        va_start(args, config);
        [self _runRequestWithConfig:config overloadConfigs:nil args:args];
        va_end(args);
    };
}

- (CAPIRequestBlock)GET
{
    return ^( id config, ... ) {
        va_list args;
        va_start(args, config);
        [self _runRequestWithConfig:config overloadConfigs:@{ @"method" : @"GET" } args:args];
        va_end(args);
    };
}

- (CAPIRequestBlock)POST
{
    return ^( id config, ... ) {
        va_list args;
        va_start(args, config);
        [self _runRequestWithConfig:config overloadConfigs:@{ @"method" : @"POST" } args:args];
        va_end(args);
    };
}

@end









