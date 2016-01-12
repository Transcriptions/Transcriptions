//
//  AVPlayer+TSCPlay.m
//  Transcriptions
//
//  Created by Jan on 12.01.16.
//
//

#import "AVPlayer+TSCPlay.h"

@implementation AVPlayer (TSCPlay)

- (void)playWithRate:(float)rate;
{
	[self play];
	self.rate = rate;
}

- (void)playWithCurrentUserDefaultRate;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	float currentRate = [defaults floatForKey:@"currentRate"];
	[self playWithRate:currentRate];
}

@end
