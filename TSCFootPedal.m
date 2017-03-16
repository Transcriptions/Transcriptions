//
//  TSCFootPedal.m
//  Transcriptions
//
//  Created by Chat on 16.03.17.
//
//

#import "TSCFootPedal.h"
#import <DDHidLib/DDHidLib.h>

@interface TSCFootPedal ()

@property DDHidQueue *pedalQueue;
@property DDHidDevice *pedalDevice;

@end

TSCFootPedal *thePedal;


@implementation TSCFootPedal


+ (TSCFootPedal *)sharedPedal
{
	if (thePedal) {
		return thePedal;
	}
	
	DDHidDevice *pedalDevice;
	NSArray *mDevices = [DDHidDevice allDevices];
	for (DDHidDevice *aDevice in mDevices)
	{
		if ([[aDevice productName] isEqualToString:@"VEC USB Footpedal"])
		{
			pedalDevice = aDevice;
		}
	}
	
	// no pedal detected.
	if (!pedalDevice) {
		return nil;
	}
	
	thePedal = [[TSCFootPedal alloc] initWithDevice: pedalDevice];
	
	return thePedal;
}



- (instancetype)initWithDevice: (DDHidDevice *)pedalDevice_in
{
	self = [super init];
	if (!self) {
		return nil;
	}
	
	self.pedalDevice = pedalDevice_in;
	
	NSArray *pedalElements = [[[self.pedalDevice elements] firstObject] elements];
	
	[self.pedalDevice open];
	self.pedalQueue = [self.pedalDevice createQueueWithSize: 30];
	[self.pedalQueue setDelegate:self];
	[self.pedalQueue addElements:pedalElements];
	[self.pedalQueue startOnCurrentRunLoop];
	
	DDHidQueue *hidQueue = self.pedalQueue;
	int64_t delayInSeconds = 2;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[hidQueue isStarted];
	});
	
	return self;
}

- (void)dealloc
{
	[self.pedalQueue stop];
	[self.pedalDevice close];
}




-(void)ddhidQueueHasEvents:(DDHidQueue *)hidQueue
{
	DDHidEvent *event;
	while ((event = [hidQueue nextEvent]))
	{
		TSCPedalButton button = TSCPedalButtonZero;
		TSCButtonState state = TSCButtonStateZero;
		switch (event.elementCookie)
		{
			case 2: button = TSCPedalButtonLeft; break;
			case 3: button = TSCPedalButtonMiddle; break;
			case 4: button = TSCPedalButtonRight; break;
			default: break;
		}
		
		switch (event.value) {
			case 0: state = TSCButtonStateReleased;break;
			case 1: state = TSCButtonStatePressed; break;
			default: break;
		}
		
		if (button != TSCButtonStateZero && state != TSCButtonStateZero)
		{
			[self.delegate onPedalButton:button state:state];
		}
	}
}


@end
