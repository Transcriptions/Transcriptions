//
//  TSCTimeStampTests.m
//  Transcriptions
//
//  Created by Jan on 19.01.16.
//
//

#import <XCTest/XCTest.h>

#import "NSString+TSCTimeStamp.h"
#import "JXCMTimeStringTransformer.h"

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
						 options:(TSCTimeStampEnumerationOptions)options
						testName:(NSString *)testName
{
#define TEST_INFO	@"Test name: %@, Source string: %@", testName, string
	
	NSUInteger stringLength = string.length;
	const NSRange stringRange = NSMakeRange(0, string.length);
	NSRange range = stringRange;
	
	BOOL lenientTest = ((options & TSCTimeStampEnumerationDoNotRequireFractionalPart) ||
						(options & TSCTimeStampEnumerationDoNotRequireNonFractionalDigitPairs));
	
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
			 XCTAssertNotNil(expectedResults, TEST_INFO);
			 
			 XCTAssertLessThan(j, expectedResults.count, TEST_INFO);
			 
			 NSString *expectedTimeCode = expectedResults[j];
			 XCTAssertEqualObjects(timeCode, expectedTimeCode, TEST_INFO);
			 
			 if (!lenientTest) {
				 NSString *timeString = [JXCMTimeStringTransformer timecodeStringForCMTime:time];
				 XCTAssertEqualObjects(timeCode, timeString, TEST_INFO);
			 }
			 
			 j += 1;
		 }];
		
		XCTAssertEqual(j, expectedResults.count, TEST_INFO);
		
		if (stringLength > 30) {
			// Allowing the parsing of long substrings would require a very complicated
			// test results setup.
			break;
		}
	}
}

- (void)testEnumeration
{
	NSDictionary *testsDict =
  @{
	// key: test name, value: test pair dictionary
	@"Example": @{
			// key: test string to parse, value: results dictionary
			@"#00:00:00.32#": @{
					// key: offset in string, value: results array for this offset
					@(0): @[@"00:00:00.32"],
					// empty/missing offset entries mean no results for this offset.
					},
			},
	@"Zero": @{
			@"#00:00:00.00#": @{
					@(0): @[@"00:00:00.00"],
					},
			},
	@"One Hour": @{
			@"#01:00:00.00#": @{
					@(0): @[@"01:00:00.00"],
					},
			},
	@"One Minute": @{
			@"#00:01:00.00#": @{
					@(0): @[@"00:01:00.00"],
					},
			},
	@"One Second": @{
			@"#00:00:01.00#": @{
					@(0): @[@"00:00:01.00"],
					},
			},
	@"One Centisecond": @{
			@"#00:00:00.01#": @{
					@(0): @[@"00:00:00.01"],
					},
			},
	@"One Millisecond": @{
			@"#00:00:00.001#": @{
					@(0): @[@"00:00:00.001"],
					},
			},
	@"Missing Values": @{
			@"#::.#": @{},
			},
	@"Too Many Sections": @{
			@"#:::.#": @{},
			},
	@"Number Sign": @{
			@"He went from #1 to #2 in a few short weeks.": @{},
			},
	@"Hash Tag": @{
			// https://twitter.com/thomassanders/status/689137669922750465
			@"“Our lives begin to end the day we become silent about things that matter.”"
			" - #MLKDay #BlackLivesMatter": @{},
			},
	@"Carol Dweck on Perfectionism": @{
			// https://www.youtube.com/watch?v=XgUF5WalyDk
			@""
			"#00:01:00.06#\n"
			"As a child, I was perfect. \n"
			"#00:01:03.39#\n"
			"I was perfectly good… at least outwardly. \n"
			"#00:01:09.09#\n"
			"Inwardly, I had a lot of mischievous thoughts. \n"
			"#00:01:13.45#\n"
			: @{
				@(0): @[@"00:01:00.06",
						@"00:01:03.39",
						@"00:01:09.09",
						@"00:01:13.45",
						],
				},
			},
	};
	
	[testsDict enumerateKeysAndObjectsUsingBlock:
	 ^(NSString *testName, NSDictionary *testPairDict, BOOL * _Nonnull stop) {
		 [testPairDict enumerateKeysAndObjectsUsingBlock:
		  ^(NSString *string, NSDictionary *results, BOOL * _Nonnull stop) {
			  [self enumerationTestForString:string
							 expectedResults:results
									 options:0
									testName:testName];
		  }];
		 
	 }];
}

- (void)testLenientEnumeration
{
	NSDictionary *lenientTestsDict =
	@{
	  @"Missing Fractional Part": @{
			  @"#00:00:01#": @{
					  @(0): @[@"00:00:01"],
					  },
			  },
	  @"Missing Fractional Digits": @{
			  @"#00:00:01.#": @{
					  @(0): @[@"00:00:01."],
					  },
			  },
	  @"Missing Values": @{
			  // The parser can be very lenient. So this is a valid time code.
			  @"#::.#": @{
					  @(0): @[@"::."],
					  },
			  },
	  @"Too Many Sections": @{
			  // … while this is not. Even with leniency. There are too many sections.
			  @"#:::.#": @{},
			  },
	  };
	
	TSCTimeStampEnumerationOptions options =
	TSCTimeStampEnumerationDoNotRequireFractionalPart |
	TSCTimeStampEnumerationDoNotRequireNonFractionalDigitPairs;
	
	[lenientTestsDict enumerateKeysAndObjectsUsingBlock:
	 ^(NSString *testName, NSDictionary *testPairDict, BOOL * _Nonnull stop) {
		 [testPairDict enumerateKeysAndObjectsUsingBlock:
		  ^(NSString *string, NSDictionary *results, BOOL * _Nonnull stop) {
			  [self enumerationTestForString:string
							 expectedResults:results
									 options:options
									testName:testName];
		  }];
		 
	 }];
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
