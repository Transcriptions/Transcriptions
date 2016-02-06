//
//  NSString+TSCTimeStamp.h
//  Transcriptions
//
//  Created by Jan on 21.12.15.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_OPTIONS(NSUInteger, TSCTimeStampEnumerationOptions) {
	TSCTimeStampEnumerationStringNotRequired = 1 << 0,
	TSCTimeStampEnumerationTimeNotRequired = 1 << 1,
	TSCTimeStampEnumerationDoNotRequireFractionalPart = 1 << 2,
	TSCTimeStampEnumerationDoNotRequireNonFractionalDigitPairs = 1 << 3,
};

@interface NSString (TSCTimeStamp)

- (BOOL)containsTimeStampDelimiter:(NSRange)range;

- (void)enumerateTimeStampsInRange:(NSRange)range
						   options:(TSCTimeStampEnumerationOptions)options
						usingBlock:(void (^ _Nonnull)(NSString * _Nullable timeCode, CMTime time, NSRange timeStampRange, BOOL * _Nonnull stop))block;

@end
