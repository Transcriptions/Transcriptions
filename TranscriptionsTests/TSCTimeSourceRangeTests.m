//
//  TSCTimeSourceRangeTests.m
//  Transcriptions
//
//  Created by Jan on 19.01.16.
//
//

#import <XCTest/XCTest.h>

#import "TSCTimeSourceRange.h"


@interface TSCTimeSourceRangeTests : XCTestCase

@end

@implementation TSCTimeSourceRangeTests

- (void)setUp
{
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (void)testNSCoding
{
	NSArray *timeSourceRanges = @[
		[TSCTimeSourceRange timeSourceRangeWithTime:CMTimeMake(0, 1)
											  range:NSMakeRange(0, 0)],
		[TSCTimeSourceRange timeSourceRangeWithTime:CMTimeMake(1, 1)
											  range:NSMakeRange(1, 1)],
	];

	NSData *timeSourceRangesData = [NSKeyedArchiver archivedDataWithRootObject:timeSourceRanges];
	XCTAssertNotNil(timeSourceRangesData);
	NSArray *unarchiveTimeSourceRanges = [NSKeyedUnarchiver unarchiveObjectWithData:timeSourceRangesData];
	XCTAssertNotNil(unarchiveTimeSourceRanges);

	XCTAssertEqualObjects(timeSourceRanges, unarchiveTimeSourceRanges);
}

@end
