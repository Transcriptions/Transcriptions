//
//  NSString+TSCTimeStamp.h
//  Transcriptions
//
//  Created by Jan on 21.12.15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (TSCTimeStamp)

- (void)enumerateTimeStampsInRange:(NSRange)range
						usingBlock:(void (^ _Nonnull)(NSString * _Nonnull timeCode, NSRange timeStampRange, BOOL * _Nonnull stop))block;

@end
