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

- (TSCLocalWhitespace)localWhitespaceForLocation:(NSUInteger)location;

@end
