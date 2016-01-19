//
//  NSString+TSCTimeStamp.m
//  Transcriptions
//
//  Created by Jan on 21.12.15.
//
//

#import "NSString+TSCTimeStamp.h"

@implementation NSString (TSCTimeStamp)

NS_INLINE CFRange CFRangeMakeFromNSRange(NSRange range) {
	return CFRangeMake((range.location == NSNotFound ? kCFNotFound : range.location), range.length);
}

- (void)enumerateTimeStampsInRange:(NSRange)range
						usingBlock:(void (^)(NSString *timeCode, NSRange timeStampRange, BOOL *stop))block;
{
	if (range.length == 0)  return;
	if (self.length == 0)  return;
	
	CFStringRef string = (__bridge CFStringRef)(self);
	
	const CFRange subRange = CFRangeMakeFromNSRange(range);
	
	CFStringInlineBuffer stringInlineBuffer;
	CFStringInitInlineBuffer(string, &stringInlineBuffer, subRange);
	
	const unichar hashMark = '#';
	const NSUInteger hashMarkLength = 1;
	
	NSUInteger start = NSNotFound;
	BOOL accumulate = NO;
	
	NSUInteger i; // Index relative to subRange.
	
	for (i = 0;
		 i < subRange.length;
		 i++) {
		UniChar codeUnit = CFStringGetCharacterFromInlineBuffer(&stringInlineBuffer, i);
		
		if (codeUnit == hashMark) {
			accumulate = !accumulate;
			
			if (start != NSNotFound) {
				const NSUInteger end = i;
				
				NSRange timeStampRange;
				timeStampRange.location = range.location + start;
				timeStampRange.length = end - start;
				
				NSString *timeCode = [self substringWithRange:timeStampRange];
				
				timeStampRange.location -= hashMarkLength;
				timeStampRange.length += 2 * hashMarkLength;
				
				BOOL stop = NO;
				
				block(timeCode, timeStampRange, &stop);
				
				if (stop) {
					break;
				}
				
				start = NSNotFound;
			}
		}
		else if (accumulate) {
			if (start == NSNotFound) {
				start = i;
			}
		}
		else {
			continue;
		}
	}
}

@end
