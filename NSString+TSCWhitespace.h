//
//  NSString+TSCWhitespace.h
//  Transcriptions
//
//  Created by Jan on 12.01.16.
//
//

#import <Foundation/Foundation.h>


typedef struct _TSCLocalWhitespace {
	BOOL prefix;
	BOOL suffix;
} TSCLocalWhitespace;


@interface NSString (TSCWhitespace)

// Returns YES, if the string is empty or contains only whitespace characters (" ", \n, \t, etc.);
- (BOOL)isBlankString;

// Returns YES, if the range is empty or contains only whitespace characters (" ", \n, \t, etc.);
- (BOOL)isBlankRange:(NSRange)fullRange;

- (TSCLocalWhitespace)localWhitespaceForLocation:(NSUInteger)location;

@end
