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

// Returns YES, if the string is empty or contains only whitespace characters (" ", \n, \t, etc.).
- (BOOL)isBlankString;

// Returns YES, if the range is empty or contains only whitespace characters (" ", \n, \t, etc.).
- (BOOL)isBlankRange:(NSRange)fullRange;

// Returns YES, if the range contains at least one line break (U+000A–U+000D, U+0085).
- (BOOL)containsLineBreak:(NSRange)range;

- (TSCLocalWhitespace)localWhitespaceForLocation:(NSUInteger)location;

@end
