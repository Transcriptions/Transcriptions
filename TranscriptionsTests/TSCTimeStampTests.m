//
//  TSCTimeStampTests.m
//  Transcriptions
//
//  Created by Jan on 19.01.16.
//
//

#import <XCTest/XCTest.h>

#import "NSString+TSCTimeStamp.h"

NS_INLINE void safelyShiftLocationInStringRangeTo(NSRange *range_p, NSUInteger location)
{
	const NSInteger delta = location - range_p->location;

	range_p->location = location;
	range_p->length = (NSInteger)range_p->length - delta;
}

@interface TSCTimeStampTests : XCTestCase

@end

@implementation TSCTimeStampTests

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

- (void)enumerationTestForString:(NSString *)string
				 expectedResults:(NSDictionary *)stringResults
{
	const NSRange stringRange = NSMakeRange(0, string.length);
	NSRange range = stringRange;
	
	TSCTimeStampEnumerationOptions options = 0;

	for (NSUInteger i = 0; i < stringRange.length; i++) {
		safelyShiftLocationInStringRangeTo(&range, stringRange.location + i);
		
		NSArray *expectedResults = stringResults[@(i)];
		
		__block NSUInteger j = 0;
		[string enumerateTimeStampsInRange:range
								   options:options
								usingBlock:
		 ^(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop) {
			 // We should not get here, when there are no expected results.
			 // This would mean that the parser found a false match.
			 XCTAssertNotNil(expectedResults);
			 
			 XCTAssertTrue(j < expectedResults.count);
			 
			 NSString *expectedTimeCode = expectedResults[j];
			 
			 XCTAssertEqualObjects(timeCode, expectedTimeCode);
			 
			 j += 1;
		 }];
		
		XCTAssertEqual(j, expectedResults.count);
	}
}

- (void)testEnumeration
{
	NSString *string = @"#00:00:00.32#";
	NSDictionary *stringResults = @{
		// key: offset in string, value: results array for this offset
		@(0): @[@"00:00:00.32"],
		// empty/missing offset entries mean no results.
	};

	[self enumerationTestForString:string
				   expectedResults:stringResults];
}

#if 0
- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}
#endif

@end
