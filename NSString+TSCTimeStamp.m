//
//  NSString+TSCTimeStamp.m
//  Transcriptions
//
//  Created by Jan on 21.12.15.
//
//

#import "NSString+TSCTimeStamp.h"

@implementation NSString (TSCTimeStamp)

- (void)enumerateTimeStampsInRange:(NSRange)range
						usingBlock:(void (^)(NSString *timeCode, NSRange timeStampRange, BOOL *stop))block;
{
	if (self.length == 0)  return;
	
	static NSCharacterSet *hashMarkSet = nil;
	static dispatch_once_t oncePredicate;
	
	dispatch_once(&oncePredicate, ^{
		hashMarkSet = [NSCharacterSet characterSetWithCharactersInString:@"#"];
	});
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	scanner.charactersToBeSkipped = nil;
	scanner.scanLocation = range.location;
	
	NSUInteger scanLocation;
	NSUInteger endLocation = NSMaxRange(range);
	
	while ((scanner.atEnd == NO) &&
		   ((scanLocation = scanner.scanLocation) != NSNotFound) &&
		    (scanLocation < endLocation)) {
		
		NSString *timeCode = nil;
		NSRange timeStampRange = NSMakeRange(NSNotFound, 0);
		
		[scanner scanUpToCharactersFromSet:hashMarkSet
								intoString:NULL];
		
		timeStampRange.location = scanner.scanLocation;
		
		BOOL scanned =
		([scanner scanString:@"#"
				  intoString:NULL] &&
		 [scanner scanUpToCharactersFromSet:hashMarkSet
								 intoString:&timeCode] &&
		 [scanner scanString:@"#"
				  intoString:NULL]);
		
		if (scanned &&
			timeCode &&
			(timeCode.length > 0)) {
			timeStampRange.length = scanner.scanLocation - timeStampRange.location;
			
			BOOL stop = NO;
			block(timeCode, timeStampRange, &stop);
			if (stop) {
				return;
			}
		}
	}
}

@end
