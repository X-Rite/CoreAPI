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
    self.capi = [CAPI with:@{ CAPIBaseURL : @"https://jsonplaceholder.typicode.com" }];
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
    
    self.capi.GET( @"/posts", nil )
    .then( ^id( CAPIResponse* response ) {
       
        [expectation fulfill];
        return nil;
        
    })
    .error( ^id(NSError* error) {
       
        [expectation fulfill];
        return nil;
        
    });

    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
    }];
}

- (void)testCachedTask
{
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __block NSUInteger count = 0;
    
    self.capi.GET( @"/posts", nil )
    .then( ^id( CAPIResponse* response ) {
        count++;
        return nil;
    })
    .error( ^id(NSError* error) {
        return nil;
    });
    
    self.capi.GET( @"/posts", nil )
    .then( ^id( CAPIResponse* response ) {
        count++;
        XCTAssertEqual(count, 2);
        [expectation fulfill];
        return nil;
    })
    .error( ^id(NSError* error) {
        [expectation fulfill];
        return nil;
    });
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
    }];
}

@end
