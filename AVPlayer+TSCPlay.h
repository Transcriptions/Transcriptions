//
//  AVPlayer+TSCPlay.h
//  Transcriptions
//
//  Created by Jan on 12.01.16.
//
//

#import <AVFoundation/AVFoundation.h>

@interface AVPlayer (TSCPlay)

- (void)playWithRate:(float)rate;
- (void)playWithCurrentUserDefaultRate;


@end
