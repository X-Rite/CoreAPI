//
//  CoreAPITests.m
//  CoreAPITests
//
//  Created by Alexander Cohen on 2016-11-06.
//  Copyright © 2016 X-Rite, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreAPI/CoreAPI.h>

@interface CoreAPITests : XCTestCase

@property (nonatomic,strong) CAPI* capi;

@end

@implementation CoreAPITests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.capi = [CAPI instanceWithConfig:@{ @"baseURL" : @"https://jsonplaceholder.typicode.com" }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.capi = nil;
}

// https://jsonplaceholder.typicode.com

- (void)testSimpleGet
{
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    self.capi.GET( @"/posts", @{ @"useContentTypeSerializer" : @YES }, ^BOOL(NSHTTPURLResponse* response) {
        
        return response.statusCode == 200;
        
    }, ^(CAPIResponse* response) {
        
        [expectation fulfill];
        
    });
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
    }];
}

@end
