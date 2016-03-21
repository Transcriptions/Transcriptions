//
//  TSCAppController.m
//  Transcriptions
//
//  Created by Jan on 28.12.15.
//
//

#import "TSCAppController.h"

#import "TSCDocumentController.h"

@implementation TSCAppController {
	TSCDocumentController *_dc;
}


- (instancetype)init
{
	self = [super init];
	
	if (self) {
		_dc = [[TSCDocumentController alloc] init];
	}
	
	return self;
}

@end
