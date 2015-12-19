//
//  TSCAppDelegate.m
//  Transcriptions
//
//  Created by Jan on 19.12.15.
//
//

#import "TSCAppDelegate.h"

#import "JXCMTimeNumberTransformer.h"
#import "JXCMTimeStringTransformer.h"

@implementation TSCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSValueTransformer *cmt;
	cmt = [[JXCMTimeNumberTransformer alloc] init];
	[NSValueTransformer setValueTransformer:cmt forName:@"JXCMTimeNumberTransformer"];
	
	cmt = [[JXCMTimeStringTransformer alloc] init];
	[NSValueTransformer setValueTransformer:cmt forName:@"JXCMTimeStringTransformer"];
	
}

@end
