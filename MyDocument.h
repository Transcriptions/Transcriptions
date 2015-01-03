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
    NSView *playerView;
    NSButton *playPauseButton;
    NSButton *fastForwardButton;
    NSButton *rewindButton;
    NSSlider *timeSlider;
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
	IBOutlet NSTextField* authorTextField;
	IBOutlet NSSlider* replaySlider;
    NSAttributedString* rtfSaveData;
    NSAttributedString* insertString;
	NSNumber* rate;
	NSString* _path;
	NSString* autor;
	NSString* copyright;
	NSString* company;
	NSString* title;
	NSString* subject;
	NSString* comment;
	NSArray* keywords;
}

@property(retain) NSString* autor;
@property(retain) NSString* copyright;		
@property(retain) NSString* company;
@property(retain) NSString* title;
@property(retain) NSString* subject;
@property(retain) NSString* comment;	
@property(retain) NSArray* keywords;

@property (retain) AVPlayer *player;
@property (retain) AVPlayerLayer *playerLayer;
@property (assign) double currentTime;
@property (readonly) double duration;
@property (assign) float volume;
@property (assign) IBOutlet NSImageView *noVideoImage;
@property (assign) IBOutlet NSView *playerView;
@property (assign) IBOutlet NSButton *playPauseButton;
@property (assign) IBOutlet NSButton *fastForwardButton;
@property (assign) IBOutlet NSButton *rewindButton;
@property (assign) IBOutlet NSSlider *timeSlider;
@property (retain) id timeObserverToken;

- (IBAction)openMovieFile:(id)sender;
- (void)openMovieFromURL:(id)sender;
- (void)setNormalSizeDisplay;
- (void)setCurrentSizeDisplay;
- (IBAction)rePlay:(id)sender;
- (NSString *)path;
- (void)setPath:(NSString *)someString;
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


@end
