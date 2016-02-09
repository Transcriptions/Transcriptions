//
//  NSString+TSCWhitespace.m
//  Transcriptions
//
//  Created by Jan on 12.01.16.
//
//

#import "NSString+TSCWhitespace.h"

@implementation NSString (TSCWhitespace)

- (BOOL)isBlankString;
{
	const NSRange fullRange = NSMakeRange(0, self.length);
	
	return [self isBlankRange:fullRange];
}

- (BOOL)isBlankRange:(NSRange)range;
{
	static NSCharacterSet *nonWhitespaceAndNewlineCharacterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		nonWhitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	});

	return ([self rangeOfCharacterFromSet:nonWhitespaceAndNewlineCharacterSet
								  options:NSLiteralSearch
									range:range].location == NSNotFound);
}

- (BOOL)containsLineBreak:(NSRange)range;
{
	static NSCharacterSet *lineBreakCharacterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		// This is designed to match the behavior of NSStringEnumerationByLines.
		lineBreakCharacterSet =
		[NSCharacterSet characterSetWithCharactersInString:@"\r" "\n" "\u2028" "\u2029"];
	});
	
	const NSRange lineBreakRange =
	[self rangeOfCharacterFromSet:lineBreakCharacterSet
						  options:NSLiteralSearch
							range:range];
	
	const BOOL hasLineBreak = (lineBreakRange.location != NSNotFound);
	return hasLineBreak;
}


- (TSCLocalWhitespace)localWhitespaceForLocation:(NSUInteger)location;
{
	TSCLocalWhitespace hasWhitespace;
	hasWhitespace.prefix = NO;
	hasWhitespace.suffix = NO;
	
	NSInteger selfLength = self.length;
	
	if (location > 0) {
		// Treat any whitespace INCLUDING line breaks as whitespace.
		NSRange range = NSMakeRange(0, location);
		const NSRange matchRange =
		[self rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
							  options:(NSLiteralSearch | NSBackwardsSearch)
								range:range];
		hasWhitespace.prefix = (matchRange.location != NSNotFound);
	}
	else {
		// Treat start of string as whitespace.
		hasWhitespace.prefix = YES;
	}
	
	if (location < selfLength) {
		// Treat any whitespace APART from line breaks as whitespace.
		NSRange range = NSMakeRange(location, selfLength - location);
		const NSRange matchRange =
		[self rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
							  options:(NSLiteralSearch)
								range:range];
		hasWhitespace.suffix = (matchRange.location != NSNotFound);
	}
	else {
		// Treat end of string as non-whitespace.
		hasWhitespace.suffix = NO;
	}
	
	return hasWhitespace;
}

@end
