//
//  TSCTimeSourceRange.h
//  Transcriptions
//
//  Created by Jan on 20.12.15.
//
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>

@interface TSCTimeSourceRange : NSObject

+ (instancetype)timeSourceRangeWithTime:(CMTime)time range:(NSRange)range;

- (instancetype)initWithTime:(CMTime)time range:(NSRange)range;

@property (nonatomic, readonly, assign) CMTime  time;
@property (nonatomic, readonly, assign) NSRange range;

@end
