//
//  NSString+TSCTimeStamp.m
//  Transcriptions
//
//  Created by Jan on 21.12.15.
//
//

#import "NSString+TSCTimeStamp.h"

#import "JXCMTimeStringTransformer.h"
#import "JXTimeCodeParserCore.h"


@implementation NSString (TSCTimeStamp)

NS_INLINE CFRange CFRangeMakeFromNSRange(NSRange range) {
	return CFRangeMake((range.location == NSNotFound ? kCFNotFound : range.location), range.length);
}

- (void)enumerateTimeStampsInRange:(NSRange)range
						   options:(TSCTimeStampEnumerationOptions)options
						usingBlock:(void (^)(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop))block;
{
	if (range.length == 0)  return;
	if (self.length == 0)  return;
	
	BOOL wantTimeCodeString = !(options & TSCTimeStampEnumerationStringNotRequired);
	BOOL wantTime = !(options & TSCTimeStampEnumerationTimeNotRequired);
	BOOL doNotRequireFractionalPart = (options & TSCTimeStampEnumerationDoNotRequireFractionalPart);
	
	CFStringRef string = (__bridge CFStringRef)(self);
	
	const CFRange subRange = CFRangeMakeFromNSRange(range);
	
	CFStringInlineBuffer stringInlineBuffer;
	CFStringInitInlineBuffer(string, &stringInlineBuffer, subRange);
	
	const unichar hashMark = '#';
	const NSUInteger hashMarkLength = 1;
	
	NSUInteger start = NSNotFound;
	BOOL accumulate = NO;
	
	const JXTimeCodeParserState parserStateDefault = {
		.position = Hours,
		.separator = ':',
		.fractionalSeparator = '.',
	};
	JXTimeCodeParserState parser = parserStateDefault;
	
	NSUInteger i; // Index relative to subRange.
	
	for (i = 0;
		 i < subRange.length;
		 i++) {
		const unichar codeUnit = CFStringGetCharacterFromInlineBuffer(&stringInlineBuffer, i);
		
		if (codeUnit == hashMark) {
			accumulate = !accumulate;
			
			if ((start != NSNotFound) &&
				((parser.position == Fractional) ||
				 (doNotRequireFractionalPart &&
				  (parser.position == Seconds)))) {
				const NSUInteger end = i;
				
				NSRange timeStampRange;
				timeStampRange.location = range.location + start;
				timeStampRange.length = end - start;
				
				NSString *timeCode = nil;
				if (wantTimeCodeString) {
					timeCode = [self substringWithRange:timeStampRange];
				}
				
				CMTime time;
				if (wantTime) {
					time = convertComponentsToCMTime(parser.components);
				}
				else {
					time = kCMTimeInvalid;
				}
				
				timeStampRange.location -= hashMarkLength;
				timeStampRange.length += 2 * hashMarkLength;
				
				BOOL stop = NO;
				
				block(timeCode, time, timeStampRange, &stop);
				
				if (stop) {
					break;
				}
				
				start = NSNotFound;
			}
		}
		else if (accumulate) {
			if (start == NSNotFound) {
				start = i;
				
				parser = parserStateDefault;
			}
			
			parseCodeUnitWithState(codeUnit, &parser);
			
			if (parser.error) {
				// Reset parser.
				start = NSNotFound;
				
				accumulate = NO;

				continue;
			}
		}
		else {
			continue;
		}
	}
}

@end
