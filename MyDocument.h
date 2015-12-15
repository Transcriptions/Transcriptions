/*
This software is Copyright (c) 2008
David Haselberger. All rights reserved.
 
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.
 
 - Neither the name of David Haselberger nor the names of any
   contributors may be used to endorse or promote products derived
   from this software without specific prior written permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import <Cocoa/Cocoa.h>
#import "TSCTextView.h"
#import "CoreMedia/CoreMedia.h"
#import "AVFoundation/AVFoundation.h"
#import "AVKit/AVKit.h"
@class AVPlayer, AVPlayerLayer;

const NSTimeInterval	k_Scrub_Slider_Update_Interval = 0.1;
const double		k_Scrub_Slider_Minimum = 0.0;

@interface MyDocument : NSDocument <NSTextViewDelegate, NSTextFieldDelegate, NSSplitViewDelegate, NSTableViewDelegate>
{
    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    NSProgressIndicator *loadingSpinner;
    NSTextField *unplayableLabel;
    NSTextField *noVideoLabel;
    NSView *__weak playerView;
    NSButton *__weak playPauseButton;
    NSButton *__weak fastForwardButton;
    NSButton *__weak rewindButton;
    NSSlider *__weak timeSlider;
    id timeObserverToken;
    
    IBOutlet NSWindow* appWindow;
	IBOutlet NSView* appContentView;
	IBOutlet TSCTextView* textView;
	IBOutlet NSSplitView* mainSplitView;
	IBOutlet NSImageView* typeImageView;
	IBOutlet NSPanel* infoPanel;
	IBOutlet NSButton* infoButton;
	IBOutlet NSPanel* URLPanel;
	IBOutlet NSTextField* URLTextField;
	IBOutlet NSPanel* HUDPanel;
	IBOutlet NSView* firstSubView;
	IBOutlet NSView* secondSubView;
	IBOutlet NSTableView* insertTableView; 
	IBOutlet NSTextField* mTextField;
	IBOutlet NSTextField* mTimeDisplay; 
	IBOutlet NSTextField* mDuration;
	IBOutlet NSTextField* charTextField;
	IBOutlet NSTextField* wordTextField;
	IBOutlet NSTextField* paragraphTextField;
	IBOutlet NSTextField* movieFileField;
	IBOutlet NSTextField* movieNormalSize;
	IBOutlet NSTextField* movieCurrentSize;
	IBOutlet NSTextField* commentTextField;
	IBOutlet NSSlider* replaySlider;
    NSAttributedString* rtfSaveData;
    NSAttributedString* insertString;
	NSNumber* rate;
	NSString* _path;
}

@property (strong) NSString* autor;
@property (strong) NSString* copyright;
@property (strong) NSString* company;
@property (strong) NSString* title;
@property (strong) NSString* subject;
@property (strong) NSString* comment;
@property (strong) NSArray* keywords;
@property (strong) NSData* mediaFileBookmark;

@property (strong) AVPlayer *player;
@property (strong) AVPlayerLayer *playerLayer;
@property (assign) double currentTime;
@property (readonly) double duration;
@property (assign) float volume;
@property (weak) IBOutlet NSImageView *noVideoImage;
@property (weak) IBOutlet NSView *playerView;
@property (weak) IBOutlet NSButton *playPauseButton;
@property (weak) IBOutlet NSButton *fastForwardButton;
@property (weak) IBOutlet NSButton *rewindButton;
@property (weak) IBOutlet NSSlider *timeSlider;
@property (strong) id timeObserverToken;

@property (weak) NSTimer *repeatingTimer;


- (IBAction)openMovieFile:(id)sender;
//- (void)openMovieFromURL:(id)sender;
- (void)setNormalSizeDisplay;
- (void)setCurrentSizeDisplay;
- (IBAction)rePlay:(id)sender;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *path;
- (IBAction)createTimeStamp:(id)sender;
- (void)openURLInDefaultBrowser:(id)sender;
- (IBAction)openHUDPanel:(id)sender;
- (void)closeHUDPanel:(id)sender;
-(NSRect)newFrameForNewHUD:(NSPanel*)panel contentView:(NSView *)view;
- (void)showMediaInfo:(id)sender;
- (void)showMediaControls:(id)sender;
- (void)doStartMediaControlSheet:(id)sender;
- (void)startSheet:(id)sender;
- (void)showInfoSheet: (NSWindow *)window;
- (void)closeInfoSheet: (id)sender;
- (void)startURLSheet:(id)sender;
- (void)showURLSheet: (NSWindow *)window;
- (void)closeURLSheet: (id)sender;
- (IBAction)reportBug:(id)sender;
-(IBAction)writeFeedback:(id)sender;
-(IBAction)redirectToDonationPage:(id)sender;

- (void)setTimestampLineNumber;
- (IBAction)startRepeatingTimer:(id)sender;
- (IBAction)stopRepeatingTimer:(id)sender;

- (IBAction)printThisDocument:(id)sender;

@end
