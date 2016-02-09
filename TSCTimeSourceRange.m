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


- (BOOL)isEqual:(id)obj
{
	if (obj == nil) {
		return NO;
	}
	
	// If parameter cannot be cast to TSCTimeSourceRange return NO.
	if (![obj isKindOfClass:[TSCTimeSourceRange class]]) {
		return NO;
	}
	
	TSCTimeSourceRange *other = (TSCTimeSourceRange *)obj;
	CMTime  otherTime = other.time;
	NSRange otherRange = other.range;
	return (CMTIME_COMPARE_INLINE(otherTime, ==, _time)
			&& NSEqualRanges(otherRange, _range));
}

- (BOOL)isEqualToTimeSourceRange:(TSCTimeSourceRange *)other
{
	if (other == nil) {
		return NO;
	}
	
	CMTime  otherTime = other.time;
	NSRange otherRange = other.range;
	return (CMTIME_COMPARE_INLINE(otherTime, ==, _time)
			&& NSEqualRanges(otherRange, _range));
}

- (NSUInteger)hash
{
#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))
	
	return ([[NSValue valueWithCMTime:_time] hash] ^ NSUINTROTATE(_range.location, NSUINT_BIT / 2)  ^ _range.length);
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeCMTime:_time forKey:@"time"];
	[encoder encodeObject:[NSValue valueWithRange:_range]
				   forKey:@"range"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	self = [self init];
	
	if (self) {
		_time = [decoder decodeCMTimeForKey:@"time"];
		_range = [[decoder decodeObjectForKey:@"range"] rangeValue];
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
