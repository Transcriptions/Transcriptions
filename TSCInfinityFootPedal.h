//
//  TSCInfinityFootPedal.h
//  Transcriptions
//
//  Created by Chat on 16.03.17.
//
//

#import <Foundation/Foundation.h>

// foot pedal buttons
typedef NS_ENUM(NSInteger, TSCPedalButton) {
	TSCPedalButtonZero,
	TSCPedalButtonLeft,
	TSCPedalButtonMiddle,
	TSCPedalButtonRight
};


// foot pedal button states
typedef NS_ENUM(NSInteger, TSCButtonState) {
	TSCButtonStateZero,
	TSCButtonStateReleased,
	TSCButtonStatePressed
};


// protocol for foot pedal messages
@protocol TSCInfinityFootPedalDelegate <NSObject>

- (void)onPedalButton:(TSCPedalButton)button state:(TSCButtonState)state;

@end


// foot pedal object
@interface TSCInfinityFootPedal : NSObject

+ (TSCInfinityFootPedal *)sharedPedal;
@property NSObject<TSCInfinityFootPedalDelegate> *delegate;

@end
