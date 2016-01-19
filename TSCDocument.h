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
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "TSCTextView.h"

@class AVPlayer, AVPlayerLayer;

FOUNDATION_EXPORT NSString * const TSCErrorDomain;

typedef NS_ENUM(NSInteger, TSCErrorCode) {
	TSCErrorWriteInapplicableStringEncodingError = 1,
};

@interface TSCDocument : NSDocument <NSTextViewDelegate, NSTextFieldDelegate, NSSplitViewDelegate, NSTableViewDelegate>
{
	//NSProgressIndicator *loadingSpinner;
    //NSTextField *unplayableLabel;
    //NSTextField *noVideoLabel;
	
    IBOutlet NSWindow *_appWindow;
	IBOutlet NSView *_appContentView;
	IBOutlet TSCTextView *_textView;
	IBOutlet NSSplitView *_mainSplitView;
	IBOutlet NSImageView *_typeImageView;
	IBOutlet NSPanel *_infoPanel;
	IBOutlet NSButton *_infoButton;
	IBOutlet NSPanel *_URLPanel;
	IBOutlet NSTextField *_URLTextField;
	IBOutlet NSPanel *_HUDPanel;
	IBOutlet NSView *_firstSubView;
	IBOutlet NSView *_secondSubView;
	IBOutlet NSTableView *_insertTableView; 
	IBOutlet NSTextField *_mTextField;
	IBOutlet NSTextField *_mTimeDisplay; 
	IBOutlet NSTextField *_mDuration;
	IBOutlet NSTextField *_charTextField;
	IBOutlet NSTextField *_wordTextField;
	IBOutlet NSTextField *_paragraphTextField;
	IBOutlet NSTextField *_movieFileField;
	IBOutlet NSTextField *_movieNormalSize;
	IBOutlet NSTextField *_movieCurrentSize;
	IBOutlet NSTextField *_commentTextField;
	IBOutlet NSSlider *_replaySlider;
    NSAttributedString *_rtfSaveData;
	
	IBOutlet NSImageView *_noVideoImage;
	IBOutlet NSView *_playerView;
	IBOutlet NSButton *_playPauseButton;
	IBOutlet NSButton *_fastForwardButton;
	IBOutlet NSButton *_rewindButton;
	IBOutlet NSSlider *_timeSlider;
	
	NSDictionary *_docAttributes;
}


@property (nonatomic, strong) NSString *autor;
@property (nonatomic, strong) NSString *copyright;
@property (nonatomic, strong) NSString *company;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSData *mediaFileBookmark;

@property (nonatomic, assign) NSStringEncoding detectedImportTextEncoding;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, assign) float volume;
@property (nonatomic, strong) id timeObserverToken;

@property (nonatomic, copy) NSString *path;

- (IBAction)openMovieFile:(id)sender;
//- (void)openMovieFromURL:(id)sender;
- (void)setNormalSizeDisplay;
- (void)setCurrentSizeDisplay;
- (IBAction)rePlay:(id)sender;
- (IBAction)createTimeStamp:(id)sender;
- (void)openURLInDefaultBrowser:(id)sender;
- (IBAction)openHUDPanel:(id)sender;
- (void)closeHUDPanel:(id)sender;
- (NSRect)newFrameForNewHUD:(NSPanel*)panel contentView:(NSView *)view;
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
- (IBAction)writeFeedback:(id)sender;
- (IBAction)redirectToDonationPage:(id)sender;

- (void)updateTimestampLineNumber;

- (IBAction)printThisDocument:(id)sender;

@end
