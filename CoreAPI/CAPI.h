//
//  CAPI.h
//  CoreAPI
//
//  Created by Alexander Cohen on 2016-11-06.
//  Copyright © 2016 X-Rite, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const CAPIErrorDomain;

@interface CAPIResponse : NSObject

@property (nonatomic,readonly) NSURLRequest* request;

@property (nonatomic,readonly) NSData* data;
@property (nonatomic,readonly) NSHTTPURLResponse* httpResponse;
@property (nonatomic,readonly) NSError* error;

@property (nonatomic,readonly) id body;

@end

typedef id _Nullable(^CAPIResponseSerialize)( NSHTTPURLResponse* httpResponse, NSData* data );
typedef BOOL(^CAPIResponseValidate)( NSHTTPURLResponse* httpResponse );
typedef void(^CAPIRequestCompletion)( CAPIResponse* response );
typedef void(^CAPIRequestBlock)( id config, ... );

@interface CAPI : NSObject

+ (instancetype)instanceWithConfig:(NSDictionary*)config;

@property (nonatomic,copy,readonly) CAPIRequestBlock request;
@property (nonatomic,copy,readonly) CAPIRequestBlock GET;
@property (nonatomic,copy,readonly) CAPIRequestBlock POST;

@end

NS_ASSUME_NONNULL_END
