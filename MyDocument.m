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


#import "MyDocument.h"


static void *TSCPlayerItemStatusContext = &TSCPlayerItemStatusContext;
static void *TSCPlayerRateContext = &TSCPlayerRateContext;
static void *TSCPlayerLayerReadyForDisplay = &TSCPlayerLayerReadyForDisplay;

@interface MyDocument ()

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
- (void)stopLoadingAnimationAndHandleError:(NSError *)error;

@end

@implementation MyDocument

@synthesize autor;
@synthesize copyright;
@synthesize company;
@synthesize title;
@synthesize subject;
@synthesize comment;
@synthesize keywords;

@synthesize player;
@synthesize playerLayer;
@synthesize noVideoImage;
@synthesize playerView;
@synthesize playPauseButton;
@synthesize fastForwardButton;
@synthesize rewindButton;
@synthesize timeSlider;
@synthesize timeObserverToken;

- (void)dealloc
{
    [player release];
    [playerLayer release];
    [super dealloc];
}

- (id)init
{
   self = [super init];
	if(self){
		autor = [NSString stringWithFormat:@""];
		copyright = [NSString stringWithFormat:@""];
		company = [NSString stringWithFormat:@""];
		title = [NSString stringWithFormat:@""];
		subject = [NSString stringWithFormat:@""];
		comment = [NSString stringWithFormat:@""];
        
    }
	return self;
}


- (NSString *)windowNibName
{
        return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
  [super windowControllerDidLoadNib:windowController];
  [[windowController window] setMovableByWindowBackground:YES];
  [[windowController window] setContentBorderThickness:32.0 forEdge:NSMinYEdge];
  [[[self playerView] layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
  if (rtfSaveData) {
        [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withAttributedString:rtfSaveData];
        [rtfSaveData release];
  }
  [textView setAllowsUndo:YES];
  [textView toggleRuler:self];
  [textView setDelegate:self];
  [mTextField  setDelegate:self];
  [mainSplitView setDelegate:self];
  [insertTableView setDelegate:self];
  [insertTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]];
  [infoPanel setMinSize:[infoPanel frame].size];
  NSTimeInterval autosaveInterval = 3;
  [[NSDocumentController sharedDocumentController] setAutosavingDelay:autosaveInterval];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processTextEditing) name:NSTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openMovieFromDrag:) name:@"movieFileDrag" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createTimeStamp:) name:@"automaticTimestamp" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToTimeStamp:) name:@"aTimestampPressed" object:nil];
    [self setPlayer:[[[AVPlayer alloc] init] autorelease]];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:TSCPlayerRateContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:TSCPlayerItemStatusContext];
}



- (void)awakeFromNib
{
	
    [[self playerView] setWantsLayer:YES];

}

	

#pragma mark loadsave

- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrapper ofType:(NSString *)type error:(NSError **)outError
{
	NSDictionary* docAttributes = [[[NSDictionary alloc] init] autorelease];
	rtfSaveData = [[NSAttributedString alloc] initWithRTF:[wrapper regularFileContents] documentAttributes:&docAttributes];   
	autor  = [docAttributes objectForKey:NSAuthorDocumentAttribute];
	copyright = [docAttributes objectForKey:NSCopyrightDocumentAttribute]; 
	company = [docAttributes objectForKey:NSCompanyDocumentAttribute];
	title = [docAttributes objectForKey:NSTitleDocumentAttribute];
	subject = [docAttributes objectForKey:NSSubjectDocumentAttribute];
	comment = [docAttributes objectForKey:NSCommentDocumentAttribute];
	keywords = [docAttributes objectForKey:NSKeywordsDocumentAttribute];

	if (textView) {                                                         
        [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withAttributedString:rtfSaveData];
        [rtfSaveData release];
	}
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return YES;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)type error:(NSError **)outError
{
    NSRange range = NSMakeRange(0,[[textView string] length]);
	
	NSDictionary* docAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								   autor, NSAuthorDocumentAttribute, copyright, NSCopyrightDocumentAttribute, company, NSCompanyDocumentAttribute, title, NSTitleDocumentAttribute, subject, NSSubjectDocumentAttribute, comment, NSCommentDocumentAttribute, keywords, NSKeywordsDocumentAttribute, nil];

	

	NSFileWrapper * wrapper = [[NSFileWrapper alloc]
							   initRegularFileWithContents:[[textView textStorage] RTFFromRange:range documentAttributes:docAttributes]];
	
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	
    return [wrapper autorelease];
 }




#pragma mark media loading and unloading

- (NSString *)path
{
	if (!_path){_path = @"";}
	return _path;
}
- (void)setPath:(NSString *)someString{
		if(!_path){
			_path = someString;
		}
		else{
			if (_path != someString)
			_path = someString;
		}
}

- (IBAction)openMovieFile:(id)sender
{
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    [panel beginSheetModalForWindow:appWindow
                  completionHandler:^(NSInteger result) {
                      if (result == NSFileHandlingPanelOKButton) {
                          NSArray* filesToOpen = [panel URLs];
                          NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[[filesToOpen objectAtIndex:0] pathExtension]];
                          [typeImage setSize:NSMakeSize(32, 32)];
                          [mTextField setStringValue:[[filesToOpen objectAtIndex:0] lastPathComponent]];
                          [typeImageView setImage:typeImage];
                          AVURLAsset *asset = [AVAsset assetWithURL:[filesToOpen objectAtIndex:0]];
                          NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
                          [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
                              dispatch_async(dispatch_get_main_queue(), ^(void) {
                                  [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
                              });
                          }];

                      }
                  }];
}


- (void)openMovieFromURL:(id)sender
{
	if ([URLTextField stringValue] != nil)
	{
		NSString* URLString = [URLTextField stringValue];
		NSURL *movieURL = [NSURL URLWithString:URLString];
		[NSApp endSheet:URLPanel];
		NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[URLString pathExtension]];
		[typeImage setSize:NSMakeSize(32, 32)];
		[mTextField setStringValue:[URLString lastPathComponent]];
		[typeImageView setImage:typeImage];
        AVURLAsset *asset = [AVAsset assetWithURL:movieURL];
        NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
        [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
            });
        }];
	}
}

- (void)openMovieFromDrag:(NSNotification*)note
{
	NSURL* movieURL = [note object];
	NSString* URLString = [movieURL absoluteString];
	NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[URLString pathExtension]];
	[typeImage setSize:NSMakeSize(32, 32)];
	[mTextField setStringValue:[URLString lastPathComponent]];
	[typeImageView setImage:typeImage];
    AVURLAsset *asset = [AVAsset assetWithURL:movieURL];
    NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
        });
    }];
}



- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
    for (NSString *key in keys)
    {
        NSError *error = nil;
        if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed)
        {
            [self stopLoadingAnimationAndHandleError:error];
            return;
        }
    }
    if (![asset isPlayable] || [asset hasProtectedContent])
    {
        [self stopLoadingAnimationAndHandleError:nil];
        return;
    }
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0)
    {
        AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
        [newPlayerLayer setFrame:[[[self playerView] layer] bounds]];
        [newPlayerLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
        [newPlayerLayer setHidden:YES];
        [[[self playerView] layer] addSublayer:newPlayerLayer];
        [self setPlayerLayer:newPlayerLayer];
        [self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:TSCPlayerLayerReadyForDisplay];
    }
    else
    {
        [self stopLoadingAnimationAndHandleError:nil];
        [[self noVideoImage] setHidden:NO];
    }
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [[self player] replaceCurrentItemWithPlayerItem:playerItem];
    [self setTimeObserverToken:[[self player] addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [[self timeSlider] setDoubleValue:CMTimeGetSeconds(time)];
        [mTimeDisplay setStringValue:[self CMTimeAsString:time]];
    }]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == TSCPlayerItemStatusContext)
    {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        BOOL enable = NO;
        switch (status)
        {
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay:
                enable = YES;
                break;
            case AVPlayerItemStatusFailed:
                [self stopLoadingAnimationAndHandleError:[[[self player] currentItem] error]];
                break;
        }
        
        [[self playPauseButton] setEnabled:enable];
        [[self fastForwardButton] setEnabled:enable];
        [[self rewindButton] setEnabled:enable];
    }
    else if (context == TSCPlayerRateContext)
    {
        float _rate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (_rate == 0.f)
        {
            //[[self playPauseButton] setTitle:@"Play"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setFloat:_rate forKey:@"currentRate"];
            //[[self playPauseButton] setTitle:@"Pause"];
        }
    }
    else if (context == TSCPlayerLayerReadyForDisplay)
    {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES)
        {
            [self stopLoadingAnimationAndHandleError:nil];
            [[self playerLayer] setHidden:NO];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
    if (error)
    {
        [self presentError:error
            modalForWindow:[self windowForSheet]
                  delegate:nil
        didPresentSelector:NULL
               contextInfo:nil];
    }
}

- (void)close
{
    [[self player] pause];
    [[self player] removeTimeObserver:[self timeObserverToken]];
    [self setTimeObserverToken:nil];
    [self removeObserver:self forKeyPath:@"player.rate"];
    [self removeObserver:self forKeyPath:@"player.currentItem.status"];
    if ([self playerLayer])
        [self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay"];
    [super close];
}


#pragma mark CMTime methods

-(NSString *)CMTimeAsString:(CMTime)time
{
    NSUInteger dTotalSeconds = CMTimeGetSeconds(time);
    NSUInteger dHours = floor(dTotalSeconds / 3600);
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
	long long timeInTenthSeconds = time.value * 10 /time.timescale;
	long long tenthSeconds =  timeInTenthSeconds % 10;
	
	return [NSString stringWithFormat:@"%lu:%lu:%lu.%lld" , (unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds, tenthSeconds];
}


+ (NSSet *)keyPathsForValuesAffectingDuration
{
    return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (double)duration
{
    AVPlayerItem *playerItem = [[self player] currentItem];
    if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
        return CMTimeGetSeconds([[playerItem asset] duration]);
    else
        return 0.f;
}

- (double)currentTime
{
    return CMTimeGetSeconds([[self player] currentTime]);
}

- (void)setCurrentTime:(double)time
{
    [[self player] seekToTime:CMTimeMakeWithSeconds(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

+ (NSSet *)keyPathsForValuesAffectingVolume
{
    return [NSSet setWithObject:@"player.volume"];
}



#pragma mark media-methods

- (void)setDurationDisplay
{
    if (self.player.currentItem)
    {
        AVPlayerItem *playerItem = [[self player] currentItem];
        if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
        {
            [mDuration setStringValue:[self CMTimeAsString:[[playerItem asset] duration]]];
        }
                                                                    
    }
}

- (float)volume
{
    return [[self player] volume];
}

- (void)setVolume:(float)volume
{
    [[self player] setVolume:volume];
}

- (void)setNormalSizeDisplay
{
    NSMutableString *sizeString = [NSMutableString string];
    NSSize movieSize = NSMakeSize(0,0);
    NSArray* videoAssets = [self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoAssets count] != 0)
    {
    movieSize = [[videoAssets objectAtIndex:0] naturalSize];
    [sizeString appendFormat:@"%.0f", movieSize.width];
    [sizeString appendString:@" x "];
    [sizeString appendFormat:@"%.0f", movieSize.height];
    [movieNormalSize setStringValue:sizeString];
    }
    else{
        [movieNormalSize setStringValue:@""];
    }
}

- (void)setCurrentSizeDisplay
{
	{
		NSSize mCurrentSize = NSMakeSize(0,0);
		mCurrentSize = [playerView bounds].size;
		NSMutableString *sizeString = [NSMutableString string];
		
		[sizeString appendFormat:@"%.0f", mCurrentSize.width];
		[sizeString appendString:@" x "];
		[sizeString appendFormat:@"%.0f", mCurrentSize.height];
		
		[movieCurrentSize setStringValue:sizeString];
	}
}

- (void)rePlay:(id)sender
{
	 if (self.player.currentItem)
    {
        CMTime currentTime = [[self player] currentTime];
        CMTime timeToAdd   = CMTimeMakeWithSeconds([replaySlider intValue],1);
        CMTime resultTime  = CMTimeSubtract(currentTime,timeToAdd);
        [[self player] seekToTime:resultTime];
        float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
        [[self player] play];
        [self.player setRate:myRate];

       	}
}

- (IBAction)playPauseToggle:(id)sender
{
    if ([[self player] rate] == 0.f)
    {
        if ([self currentTime] == [self duration])
        {
            [self setCurrentTime:0.f];
        }
        float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
        [[self player] play];
        [self.player setRate:myRate];
    }
    else
    {
        [[self player] pause];
    }
}


- (IBAction)fastForward:(id)sender
{
    if ([[self player] rate] < 2.f)
    {
        [[self player] setRate:2.f];
    }
    else
    {
        [[self player] setRate:[[self player] rate] + 2.f];
    }
}

- (IBAction)rewind:(id)sender
{
    if ([[self player] rate] > -2.f)
    {
        [[self player] setRate:-2.f];
    }
    else
    {
        [[self player] setRate:[[self player] rate] - 2.f];
    }
}




#pragma mark timeStamp methods

//==> AVASSET CODE FOR TIMESTAMPS!!!!!!!!

- (void)createTimeStamp:(id)sender
{
	if(self.player.currentItem){
		NSMutableDictionary* stampAttributes;
		stampAttributes = [NSMutableDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		[stampAttributes setObject:[NSFont systemFontOfSize:12] forKey: NSFontAttributeName];
	
		NSString* stringToInsert = [NSString stringWithFormat:@"#%@#", [self CMTimeAsString:[self.player currentTime]]];
	
		[textView insertText:@" "];
		[textView insertText:stringToInsert];
		[textView insertText:@" "];
	
		[[textView textStorage] addAttributes:stampAttributes  range:[[textView string] rangeOfString:stringToInsert]];
		
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue] == YES)
		{
			[textView insertText:@"\n"];
		}
	
	}
}

- (void)jumpToTimeStamp:(NSNotification *)note
{
    NSString* timestampTimeString = [note object];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"timestampReplay"] boolValue] == YES )
	{
		CMTime timeToAdd   = CMTimeMakeWithSeconds([replaySlider intValue],1);
        CMTime resultTime  = CMTimeSubtract([self cmtimeForTimeStampString:timestampTimeString],timeToAdd);
        [[self player] seekToTime:resultTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
        [[self player] play];
        [self.player setRate:myRate];
	}else
    {
    [[self player] seekToTime:[self cmtimeForTimeStampString:timestampTimeString] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (CMTime)cmtimeForTimeStampString:(NSString *)tsString
{
	NSArray* timeComponents = [tsString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":-."]];
    float hours = [[timeComponents objectAtIndex:0] floatValue];
    float minutes = [[timeComponents objectAtIndex:1] floatValue];
    float seconds = [[timeComponents objectAtIndex:2] floatValue];
    float tenthsecond  = [[timeComponents objectAtIndex:3] floatValue];
    Float64 timeInSeconds = (hours * 3600.0f) + (minutes * 60.0f) + seconds + (tenthsecond * 0.1f);
    //CMTimeScale myTimeScale = self.player.currentItem.asset.duration.timescale;
    
    return CMTimeMakeWithSeconds(timeInSeconds, 1);
}

#pragma mark textStorage activities

- (void)processTextEditing
{

}

#pragma mark SplitView delegate methods

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMax > splitView.frame.size.width - 250)
    {
        proposedMax = splitView.frame.size.width - 250;
    }
    
    return proposedMax ;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

#pragma mark Media Control HUD panel

- (void)doStartMediaControlSheet:(id)sender
{
	[self openHUDPanel:self];
}


- (void)openHUDPanel:(id)sender
{
	
	if (![HUDPanel isVisible]){
		if ([[[HUDPanel contentView] subviews] count] == 0){
			
			NSRect initialFrame = [self newFrameForNewHUD:HUDPanel contentView:firstSubView];
			[HUDPanel setContentSize:[firstSubView frame].size];
			[HUDPanel setTitle:@"Media Controls"];
			[[HUDPanel contentView] addSubview:firstSubView];
			[[HUDPanel contentView] setWantsLayer:YES];
			[HUDPanel setMinSize:initialFrame.size];
		}else if ([[[HUDPanel contentView] subviews] containsObject:secondSubView])
		{
			NSRect changeAfterOpenFrame = [self newFrameForNewHUD:HUDPanel contentView:firstSubView];
			[NSAnimationContext beginGrouping];

			[HUDPanel setTitle:@"Media Controls"];
			[[[HUDPanel contentView] animator] replaceSubview:secondSubView with:firstSubView];
			[[HUDPanel animator] setFrame:changeAfterOpenFrame display:YES];	
			
			[NSAnimationContext endGrouping];
			[HUDPanel setMinSize:changeAfterOpenFrame.size];

		}
		
		[HUDPanel orderFront:sender];
	
		[infoButton setAction: @selector(closeHUDPanel:)];
	}else{
		[self closeHUDPanel:self];
	}
	

}

- (void)closeHUDPanel:(id)sender
{
	if ([HUDPanel isVisible]){
		[HUDPanel orderOut:sender];
		[infoButton setAction: @selector(openHUDPanel:)];
	}else{
		[self openHUDPanel:self];
	}


}

- (void)showMediaInfo:(id)sender
{
	NSRect newFrame = [self newFrameForNewHUD:HUDPanel contentView:secondSubView];
	
	[NSAnimationContext beginGrouping];
	
	[HUDPanel setTitle:@"Media Information"];

	[[[HUDPanel contentView] animator] replaceSubview:firstSubView with:secondSubView];
	[[HUDPanel animator] setFrame:newFrame display:YES];

	[NSAnimationContext endGrouping];
	[HUDPanel setMinSize:newFrame.size];
	
	if (self.player.currentItem){
		[self setNormalSizeDisplay];
		[self setCurrentSizeDisplay];
		[self setDurationDisplay];
		[movieFileField setStringValue:[[self urlOfCurrentlyPlayingInPlayer:self.player] absoluteString]];
	}
}

-(NSURL *)urlOfCurrentlyPlayingInPlayer:(AVPlayer *)_player{
    AVAsset *currentPlayerAsset = _player.currentItem.asset;
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    return [(AVURLAsset *)currentPlayerAsset URL];
}

- (void)showMediaControls:(id)sender
{
	NSRect firstFrame = [self newFrameForNewHUD:HUDPanel contentView:firstSubView];
	[NSAnimationContext beginGrouping];
	[HUDPanel setTitle:@"Media Controls"];
	[[[HUDPanel contentView] animator] replaceSubview:secondSubView with:firstSubView];
	[[HUDPanel animator] setFrame:firstFrame display:YES];
	[NSAnimationContext endGrouping];
	[HUDPanel setMinSize:firstFrame.size];
}

-(NSRect)newFrameForNewHUD:(NSPanel*)panel contentView:(NSView *)view {
    
	NSRect newFrameRect = [panel frameRectForContentRect:[view frame]];
    NSRect oldFrameRect = [panel frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    NSRect frame = [panel frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    return frame;
}


# pragma mark HELP and Info

-(void)openURLInDefaultBrowser:(id)sender
{
	
	NSURL* url = [NSURL URLWithString:@"http://code.google.com/p/transcriptions/"];
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
					withAppBundleIdentifier:NULL
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
}

-(IBAction)reportBug:(id)sender{
	
    NSURL* url = [NSURL URLWithString:@"https://code.google.com/p/transcriptions/issues/list"];
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
                    withAppBundleIdentifier:NULL
                                    options:NSWorkspaceLaunchDefault
             additionalEventParamDescriptor:NULL
                          launchIdentifiers:NULL];
	
}

-(IBAction)writeFeedback:(id)sender{
    
    NSString* mailToString = @"mailto:transcriptionsdev@gmail.com";
    NSURL* emailURL = [NSURL URLWithString:mailToString];
    [[NSWorkspace sharedWorkspace] openURL:emailURL];
    
}

-(IBAction)redirectToDonationPage:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"http://www.unet.univie.ac.at/~a0206600/TranscriptionsDonate.html"];
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
					withAppBundleIdentifier:NULL
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
}
	
#pragma mark Document Informations Panel METHODS


// ==> ADD BETTER CALCULATIONS FOR WORD AND CHARACTER COUNTS
- (void)startSheet:(id)sender
{
	NSArray* charArray = [[textView textStorage] characters];
	NSString* charRepresentation = [NSString stringWithFormat:@"%lu", (unsigned long)[charArray count]];

	//see:http://www.cocoadev.com/index.pl?NSStringCategory 
	NSMutableCharacterSet* wordSet = [NSMutableCharacterSet letterCharacterSet];
	[wordSet addCharactersInString:@"-"];
	
	NSScanner* scanner      = [NSScanner scannerWithString:[textView string]];
	NSMutableArray* wordArray      = [NSMutableArray array];
	
	[scanner setCharactersToBeSkipped:[wordSet invertedSet]];
	
	while (![scanner isAtEnd])
	{
		NSString* destination = [NSString string];
		
		if ([scanner scanCharactersFromSet:wordSet intoString:&destination])
		{
			[wordArray addObject:[NSString stringWithString:destination]];
		}
	}
	
	NSString* wordRepresentation = [NSString stringWithFormat:@"%lu",(unsigned long)[[wordArray copy] count]];
	
	NSArray *lines = [[textView string] componentsSeparatedByString:@"\n"];	
	int i;
	int emptyString = 0;
	int parNumber = 0;
	
	NSString *s = [NSString stringWithFormat:@"%i", parNumber];
	
	for (i=0;i<[lines count];i++) {
			if ([[lines objectAtIndex:i] length] > 0){
					parNumber = (i + 1) - emptyString;
					s = [NSString stringWithFormat:@"%i", parNumber];
				}
			else{
				emptyString += 1;
			}
	}


	[paragraphTextField setStringValue:s];
	[wordTextField setStringValue:wordRepresentation];
	[charTextField setStringValue:charRepresentation];
	
	[self showInfoSheet:appWindow];

	
}


- (void)showInfoSheet: (NSWindow *)window
{
    [NSApp beginSheet:infoPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}


- (void)closeInfoSheet: (id)sender
{
    [NSApp endSheet:infoPanel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}



- (void)startURLSheet:(id)sender
{
	[self showURLSheet:appWindow];
}


- (void)showURLSheet: (NSWindow *)window
{
	[NSApp beginSheet:URLPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
	[URLPanel setMinSize:[URLPanel frame].size];
	[URLPanel setMaxSize:[URLPanel frame].size];
}

- (void)closeURLSheet: (id)sender
{
	[NSApp endSheet:URLPanel];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if (outError != NULL)
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if (outError != NULL)
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    return YES;
}


@end



