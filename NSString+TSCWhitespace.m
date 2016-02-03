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
	
	static NSRegularExpression *whitespaceCharacterRegEx = nil;
	static dispatch_once_t oncePredicate;
	
	dispatch_once(&oncePredicate, ^{
		NSError *error = nil;
		
		whitespaceCharacterRegEx =
		[[NSRegularExpression alloc] initWithPattern:@"\\s"
											 options:0
											   error:&error];
		
		if (!whitespaceCharacterRegEx) {
			NSLog(@"%@", error);
			exit(EXIT_FAILURE);
		}
	});
	
	if (location > 0) {
		NSRange codeUnitRange = NSMakeRange(location - 1, 1);
		NSRange matchRange =
		[whitespaceCharacterRegEx rangeOfFirstMatchInString:self
													options:(NSMatchingAnchored | NSMatchingWithTransparentBounds)
													  range:codeUnitRange];
		hasWhitespace.prefix = (matchRange.location != NSNotFound);
	}
	else {
		// Treat start of string as whitespace.
		hasWhitespace.prefix = YES;
	}
	
	if (location < selfLength) {
		NSRange codeUnitRange = NSMakeRange(location, 1);
		NSRange matchRange =
		[whitespaceCharacterRegEx rangeOfFirstMatchInString:self
													options:(NSMatchingAnchored | NSMatchingWithTransparentBounds)
													  range:codeUnitRange];
		hasWhitespace.suffix = (matchRange.location != NSNotFound);
	}
	else {
		// Treat end of string as non-whitespace.
		hasWhitespace.suffix = NO;
	}
	
	return hasWhitespace;
}

@end
