//
//  TSCTimeSourceRange.m
//  Transcriptions
//
//  Created by Jan on 20.12.15.
//
//

#import "TSCTimeSourceRange.h"

@implementation TSCTimeSourceRange

+ (instancetype)timeSourceRangeWithTime:(CMTime)time range:(NSRange)range;
{
	id result = [[[self class] alloc] initWithTime:time range:range];
	
	return result;
}

- (instancetype)initWithTime:(CMTime)time range:(NSRange)range;
{
	self = [super init];
	
	if (self) {
		_time = time;
		_range = range;
	}
	
	return self;
}

- (NSString *)description;
{
	NSString *description = [NSString stringWithFormat:@"<%@ %p, time:%@, range:%@>",
							 NSStringFromClass([self class]), self,
							 CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _time)),
							 NSStringFromRange(_range)];
	return description;
}

@end
