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
#include <unistd.h>


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
@synthesize mediaFileBookmark;

@synthesize player;
@synthesize playerLayer;
@synthesize noVideoImage;
@synthesize playerView;
@synthesize playPauseButton;
@synthesize fastForwardButton;
@synthesize rewindButton;
@synthesize timeSlider;
@synthesize timeObserverToken;

@synthesize repeatingTimer;

+ (BOOL)autosavesInPlace
{
    return YES;
}

+ (BOOL)autosavesDrafts
{
    return YES;
}

+ (BOOL)preservesVersions {
    return YES;
}

- (instancetype)init
{
   self = [super init];
	if(self){

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
  }
  [textView setAllowsUndo:YES];
  [textView toggleRuler:self];
  [textView setDelegate:self];
  [mTextField  setDelegate:self];
  [mainSplitView setDelegate:self];
  [insertTableView setDelegate:self];
  [insertTableView registerForDraggedTypes:@[NSStringPboardType, NSRTFPboardType]];
  [infoPanel setMinSize:[infoPanel frame].size];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processTextEditing) name:NSTextDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openMovieFromDrag:) name:@"movieFileDrag" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createTimeStamp:) name:@"automaticTimestamp" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToTimeStamp:) name:@"aTimestampPressed" object:nil];
  [self setPlayer:[[AVPlayer alloc] init]];
  [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:TSCPlayerRateContext];
  [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:TSCPlayerItemStatusContext];
  [self setTimestampLineNumber];
}




- (void)awakeFromNib
{
    NSTimeInterval autosaveInterval = 2.0;
    [[NSDocumentController sharedDocumentController] setAutosavingDelay:autosaveInterval];
    [[self playerView] setWantsLayer:YES];
    NSButton *closeButton = [appWindow standardWindowButton:NSWindowCloseButton];
    NSView *titleBarView = closeButton.superview;
    NSButton* myHelpButton = [[NSButton alloc] initWithFrame:NSMakeRect(titleBarView.bounds.size.width - 30,titleBarView.bounds.origin.y, 25, 25)];
    [myHelpButton setBezelStyle:NSHelpButtonBezelStyle];
    [myHelpButton setTitle:@""];
    [myHelpButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [myHelpButton setAction:@selector(showHelp:)];
    [myHelpButton setTarget:[NSApplication sharedApplication]];
    [titleBarView addSubview:myHelpButton];
    if ([comment length] > 0)
    {
        NSString* foundUrlString;
        if ([comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound)
        {
         foundUrlString = [NSString stringWithString:[self getDataBetweenFromString:comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21]];
        }
        if ([foundUrlString length] > 0) {
            NSData *myData = [[NSData alloc] initWithBase64EncodedString:foundUrlString options:0];
            [self setMediaFileBookmark:myData];
            if (mediaFileBookmark)
            {
                NSError *error = nil;
                BOOL bookmarkDataIsStale;
                NSURL *bookmarkFileURL = nil;
                bookmarkFileURL = [NSURL
                                   URLByResolvingBookmarkData:mediaFileBookmark
                                   options:NSURLBookmarkResolutionWithSecurityScope
                                   relativeToURL:nil
                                   bookmarkDataIsStale:&bookmarkDataIsStale
                                   error:&error];
                [bookmarkFileURL startAccessingSecurityScopedResource];
//                if ([[NSFileManager defaultManager] isReadableFileAtPath:bookmarkFileURL.path]) {
//                    NSLog(@"FileManager: Yes.");
//                }
//                if (access([[bookmarkFileURL path] UTF8String], R_OK) != 0)
//                {
//                    NSLog(@"Sandbox: No.");
//                }
                NSError *err;
                if ([bookmarkFileURL checkResourceIsReachableAndReturnError:&err] == NO)
                {
                    [[NSAlert alertWithError:err] runModal];
                }
                else if([bookmarkFileURL isFileURL] == YES)
                {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:bookmarkFileURL];
                    NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
                    NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[bookmarkFileURL pathExtension]];
                    [typeImage setSize:NSMakeSize(32, 32)];
                    [mTextField setStringValue:[bookmarkFileURL lastPathComponent]];
                    [typeImageView setImage:typeImage];
                    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
                        });
                    }];
                }
            }
        }
    }
}

- (BOOL)revertToContentsOfURL:(NSURL *)inAbsoluteURL
                       ofType:(NSString *)inTypeName
                        error:(NSError **)outError {

    BOOL reverted = [super revertToContentsOfURL:inAbsoluteURL
                                          ofType:inTypeName
                                           error:outError];
    if (reverted) {
    }
    return YES;
}


- (void)close
{
    [super close];
}

-(void)dealloc
{
    [[self player] pause];
    [[self player] removeTimeObserver:[self timeObserverToken]];
    [self setTimeObserverToken:nil];
    [self removeObserver:self forKeyPath:@"player.rate"];
    [self removeObserver:self forKeyPath:@"player.currentItem.status"];
    if ([self playerLayer])
        [self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay"];
    [[self player] replaceCurrentItemWithPlayerItem:nil];
    
}


#pragma mark text edit processing
- (void)processTextEditing
{
    
}

- (void)textDidChange:(NSNotification *)notification
{
    [self updateChangeCount:NSChangeDone];
    [textView setNeedsDisplay:YES];
}


#pragma mark loadsave

- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrapper ofType:(NSString *)type error:(NSError **)outError
{
	NSDictionary* docAttributes = [[NSDictionary alloc] init];
	rtfSaveData = [[NSAttributedString alloc] initWithRTF:[wrapper regularFileContents] documentAttributes:&docAttributes];
    autor  = docAttributes[NSAuthorDocumentAttribute];
	copyright = docAttributes[NSCopyrightDocumentAttribute];
	company = docAttributes[NSCompanyDocumentAttribute];
	title = docAttributes[NSTitleDocumentAttribute];
	subject = docAttributes[NSSubjectDocumentAttribute];
	comment = docAttributes[NSCommentDocumentAttribute];
	keywords = docAttributes[NSKeywordsDocumentAttribute];
    if ([rtfSaveData length] > 0) {
         [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withAttributedString:rtfSaveData];
    }
    if ([keywords count] == 1) {
        NSString* firstObject = [keywords objectAtIndex:0];
        if ([firstObject isEqualToString:@""]) {
            keywords = nil;
        }
    }
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return YES;
}

- (NSString *)getDataBetweenFromString:(NSString *)data leftString:(NSString *)leftData rightString:(NSString *)rightData leftOffset:(NSInteger)leftPos;
{
    NSInteger left, right;
    NSString *foundData;
    NSScanner *scanner=[NSScanner scannerWithString:data];
    [scanner scanUpToString:leftData intoString: nil];
    left = [scanner scanLocation];
    [scanner setScanLocation:left + leftPos];
    [scanner scanUpToString:rightData intoString: nil];
    right = [scanner scanLocation] + 1;
    left += leftPos;
    foundData = [NSString stringWithString:[data substringWithRange: NSMakeRange(left, (right - left) - 1)]];
    return foundData;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)type error:(NSError **)outError
{
   NSRange range = NSMakeRange(0,[[textView string] length]);
    if ([autor length] <= 0) {
        autor = [NSString stringWithFormat:@""];
    }
    if ([copyright length] <= 0) {
        copyright = [NSString stringWithFormat:@""];
    }
    if ([company length] <= 0) {
        company = [NSString stringWithFormat:@""];
    }
    if ([title length] <= 0) {
        title = [NSString stringWithFormat:@""];
    }
    if ([subject length] <= 0) {
        subject = [NSString stringWithFormat:@""];
    }
    if ([comment length] <= 0) {
        comment = [NSString stringWithFormat:@""];
    }
    if ([keywords count] == 0) {
        keywords = [NSArray arrayWithObject:@""];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mediaFileAssoc"] boolValue] == YES)
    {
        if ([comment length] > 0)
        {
            if ([comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound) {
                NSString* foundUrlString = [self getDataBetweenFromString:comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21];
                if ([foundUrlString length] > 0)
                {
                    NSString* toBeRemoved = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]",foundUrlString];
                    NSString* newComment = [comment stringByReplacingOccurrencesOfString:toBeRemoved withString:@""];
                    comment = newComment;
                }
            }
        }
        NSError *error = nil;
        BOOL bookmarkDataIsStale;
        NSURL *bookmarkFileURL = nil;
        bookmarkFileURL = [NSURL
                           URLByResolvingBookmarkData:mediaFileBookmark
                           options:NSURLBookmarkResolutionWithSecurityScope
                           relativeToURL:nil
                           bookmarkDataIsStale:&bookmarkDataIsStale
                           error:&error];
        NSError* err;
        NSURL* fileUrl = [self urlOfCurrentlyPlayingInPlayer:self.player];
        if ([[fileUrl path] compare:[bookmarkFileURL path]] == NSOrderedSame && [fileUrl checkResourceIsReachableAndReturnError:&err] == YES && [fileUrl isFileURL] == YES)
        {
            NSString *utfString = [mediaFileBookmark base64EncodedStringWithOptions:(nil)];
            NSString* urlForComment = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]",utfString];
            NSString* commentString = [NSString stringWithFormat:@"%@%@",comment, urlForComment];
            comment = commentString;
            [commentTextField setStringValue:comment];
        }
    }
	NSDictionary* docAttributes = @{NSAuthorDocumentAttribute: autor, NSCopyrightDocumentAttribute: copyright, NSCompanyDocumentAttribute: company, NSTitleDocumentAttribute: title, NSSubjectDocumentAttribute: subject, NSCommentDocumentAttribute: comment, NSKeywordsDocumentAttribute: keywords};
	NSFileWrapper * wrapper = [[NSFileWrapper alloc]
							   initRegularFileWithContents:[[textView textStorage] RTFFromRange:range documentAttributes:docAttributes]];
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return wrapper;
}



#pragma mark media loading and unloading

- (IBAction)openMovieFile:(id)sender
{
    if (mediaFileBookmark) {
        NSError *error = nil;
        BOOL bookmarkDataIsStale;
        NSURL *bookmarkFileURL = nil;
        bookmarkFileURL = [NSURL
                           URLByResolvingBookmarkData:mediaFileBookmark
                           options:NSURLBookmarkResolutionWithSecurityScope
                           relativeToURL:nil
                           bookmarkDataIsStale:&bookmarkDataIsStale
                           error:&error];
        [bookmarkFileURL stopAccessingSecurityScopedResource];
    }
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    [panel beginSheetModalForWindow:appWindow
                  completionHandler:^(NSInteger result) {
                      if (result == NSFileHandlingPanelOKButton) {
                          NSArray* filesToOpen = [panel URLs];
                          NSError *error = nil;
                          [self setMediaFileBookmark:[filesToOpen[0]
                                          bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                          includingResourceValuesForKeys:nil
                                          relativeToURL:nil
                                          error:&error]];
                          NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[filesToOpen[0] pathExtension]];
                          [typeImage setSize:NSMakeSize(32, 32)];
                          [mTextField setStringValue:[filesToOpen[0] lastPathComponent]];
                          [typeImageView setImage:typeImage];
                          AVURLAsset *asset = [AVURLAsset assetWithURL:filesToOpen[0]];
                          NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
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
        AVURLAsset *asset = [AVURLAsset assetWithURL:movieURL];
        NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
        [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
            });
        }];
	}
}

//- (void)openMovieFromDrag:(NSNotification*)note
//{
//	NSURL* movieURL = [note object];
//	NSString* URLString = [movieURL absoluteString];
//	NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[URLString pathExtension]];
//	[typeImage setSize:NSMakeSize(32, 32)];
//	[mTextField setStringValue:[URLString lastPathComponent]];
//	[typeImageView setImage:typeImage];
//    AVURLAsset *asset = [AVAsset assetWithURL:movieURL];
//    NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
//    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
//        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
//        });
//    }];
//}



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
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
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
        float _rate = [change[NSKeyValueChangeNewKey] floatValue];
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
        if ([change[NSKeyValueChangeNewKey] boolValue] == YES)
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



#pragma mark CMTime methods

-(NSString *)CMTimeAsString:(CMTime)time
{
    NSUInteger dTotalSeconds = CMTimeGetSeconds(time);
    NSUInteger dHours = floor(dTotalSeconds / 3600);
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
    long long tenthSeconds = 0;
    if(time.timescale)
    {
        long long timeInTenthSeconds = time.value * 10 /time.timescale;
        tenthSeconds =  timeInTenthSeconds % 10;
    }
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
     [self setTimestampLineNumber];
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
    NSSize movieSize;
    NSArray* videoAssets = [self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoAssets count] != 0)
    {
    movieSize = [videoAssets[0] naturalSize];
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
		NSSize mCurrentSize;
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
        [self setTimestampLineNumber];
        [self startRepeatingTimer:self];
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
        [self setTimestampLineNumber];
        [self startRepeatingTimer:self];
    }
    else
    {
        [[self player] pause];
        [self stopRepeatingTimer:self];
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

- (void)createTimeStamp:(id)sender
{
	if(self.player.currentItem){
		NSMutableDictionary* stampAttributes;
		stampAttributes = [NSMutableDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		stampAttributes[NSFontAttributeName] = [NSFont systemFontOfSize:12];
        NSString* timeString = [self CMTimeAsString:[self.player currentTime]];
		NSString* stringToInsert = [NSString stringWithFormat:@"#%@#", timeString];
		[textView insertText:@" "];
		[textView insertText:stringToInsert];
		[textView insertText:@" "];
		[[textView textStorage] addAttributes:stampAttributes  range:[[textView string] rangeOfString:stringToInsert]];
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue] == YES)
		{
			[textView insertText:@"\n"];
		}
        [self setTimestampLineNumber];
	}
}

- (void)jumpToTimeStamp:(NSNotification *)note
{
    NSButton* tsButton = [note object];
    if (tsButton.window == appWindow) {
        NSString* timestampTimeString = tsButton.title;
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"timestampReplay"] boolValue] == YES )
        {
            CMTime timeToAdd   = CMTimeMakeWithSeconds([replaySlider intValue],1);
            CMTime resultTime  = CMTimeSubtract([self cmtimeForTimeStampString:timestampTimeString],timeToAdd);
            [[self player] seekToTime:resultTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
            [[self player] play];
            [self.player setRate:myRate];
        }
        else
        {
            [[self player] seekToTime:[self cmtimeForTimeStampString:timestampTimeString] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        }
        [self setTimestampLineNumber];
        [self startRepeatingTimer:self];
    }
}

- (CMTime)cmtimeForTimeStampString:(NSString *)tsString
{
	NSArray* timeComponents = [tsString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":-."]];
	if (timeComponents.count < 4)  return kCMTimeInvalid;
	
    float hours = [timeComponents[0] floatValue];
    float minutes = [timeComponents[1] floatValue];
    float seconds = [timeComponents[2] floatValue];
    float tenthsecond  = [timeComponents[3] floatValue];
    Float64 timeInSeconds = (hours * 3600.0f) + (minutes * 60.0f) + seconds + (tenthsecond * 0.1f);    
    return CMTimeMakeWithSeconds(timeInSeconds, 1);
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
	[[NSWorkspace sharedWorkspace] openURLs:@[url]
					withAppBundleIdentifier:NULL
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
}

-(IBAction)reportBug:(id)sender{
	
    NSURL* url = [NSURL URLWithString:@"https://code.google.com/p/transcriptions/issues/list"];
    [[NSWorkspace sharedWorkspace] openURLs:@[url]
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
	[[NSWorkspace sharedWorkspace] openURLs:@[url]
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
			if ([lines[i] length] > 0){
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
    [self.windowForSheet beginSheet:infoPanel completionHandler:^(NSModalResponse returnCode) {
		[infoPanel orderOut:self];
	}];
}

- (void)closeInfoSheet: (id)sender
{
    [self.windowForSheet endSheet:infoPanel];
}


- (void)startURLSheet:(id)sender
{
	[self showURLSheet:appWindow];
}


- (void)showURLSheet: (NSWindow *)window
{
	[self.windowForSheet beginSheet:URLPanel completionHandler:^(NSModalResponse returnCode) {
		[URLPanel orderOut:self];
	}];
	// FIXME: Is this still necessary? Looks like a hack. ;)
	[URLPanel setMinSize:[URLPanel frame].size];
	[URLPanel setMaxSize:[URLPanel frame].size];
}

- (void)closeURLSheet: (id)sender
{
	[self.windowForSheet endSheet:URLPanel];
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



#pragma mark timestamp line numbers

- (void)setTimestampLineNumber
{
    NSString* theString = [self->textView string];
    NSMutableArray* myTimeValueArray = [NSMutableArray arrayWithCapacity:10];
    if ([theString length] != 0)
    {
        NSScanner* lineScanner = [NSScanner scannerWithString:theString];
        NSCharacterSet* rauteSet = [NSCharacterSet characterSetWithCharactersInString:@"#"];
        NSString* tscTimeValue;
        NSString* rauteA;
        NSString* rauteB;
        while ([lineScanner isAtEnd] == NO && [lineScanner scanLocation] != NSNotFound)
        {
            BOOL scanned;
            if([[theString substringFromIndex:[lineScanner scanLocation]] compare:@"#"] != NSOrderedSame)
            {[lineScanner scanUpToCharactersFromSet:rauteSet intoString:NULL];}
            scanned = [lineScanner scanString:@"#" intoString:&rauteA] &&
            [lineScanner scanUpToCharactersFromSet:rauteSet intoString:&tscTimeValue] &&
            [lineScanner scanString:@"#" intoString:&rauteB];
            if (scanned && [tscTimeValue length] > 0){
                if([myTimeValueArray count] > 1)
                {
                    [myTimeValueArray removeObjectIdenticalTo:tscTimeValue];
                }
                [myTimeValueArray addObject:tscTimeValue];
            }
        }
    }
    AVPlayerItem *playerItem = [[self player] currentItem];
    [myTimeValueArray addObject:[self CMTimeAsString:CMTimeAbsoluteValue([[playerItem asset] duration])]];
    NSArray* myTimeArray = [myTimeValueArray copy];
    NSArray *sortedValues = [myTimeArray sortedArrayUsingComparator: ^(id obj1, id obj2) {
        CMTime a = [self cmtimeForTimeStampString:obj1];
        CMTime b = [self cmtimeForTimeStampString:obj2];
        if (CMTimeCompare(a, b) < 0)
            return NSOrderedAscending;
        else if (CMTimeCompare(a, b) > 0)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    NSString *currentTimeStampTimeString = [[NSString alloc] init];
    for (int x = 0; x < [sortedValues count]; x++) {
        CMTime timeStampTime = [self cmtimeForTimeStampString:sortedValues[x]];
        CMTime timeStampTimeNext;
        if (x < [sortedValues count] - 1)
        {
            timeStampTimeNext   = [self cmtimeForTimeStampString:sortedValues[x + 1]];
        }else{
            timeStampTimeNext   = CMTimeAbsoluteValue([[playerItem asset] duration]);
        }
        CMTime currentTime = CMTimeAbsoluteValue([[self player] currentTime]);
        if (CMTimeCompare(timeStampTime,currentTime) >= 0 && CMTimeCompare(timeStampTime, timeStampTimeNext) < 0)
        {
            if (x == 0)
            {
                currentTimeStampTimeString = sortedValues[x];
            }
            else
            {
                currentTimeStampTimeString = sortedValues[x - 1];
            }
            break;
        }
    }
    if (!(currentTimeStampTimeString.length == 0)) {
        CMTime comparisonTimeStampTime = [self cmtimeForTimeStampString:currentTimeStampTimeString];
        CMTime currentTime = CMTimeAbsoluteValue([[self player] currentTime]);
        int32_t comparison = CMTimeCompare(comparisonTimeStampTime, currentTime);
        if (comparison <= 0) {
            NSArray* lines = [[self->textView string] componentsSeparatedByString:@"\n"];
            int newTimeStampLineNumber = 0;
            int i;
            int emptyString = 0;
            for (i=0;i<[lines count];i++) {
                if (![lines[i] isEqualToString:@"\n"]&&[lines[i] length] > 0)
                {
                            if ([lines[i] rangeOfString:[NSString stringWithFormat:@"#%@#", currentTimeStampTimeString]].location != NSNotFound)
                    {
                        int insertNumber = (i + 1) - emptyString;
                        newTimeStampLineNumber = insertNumber;
                        break;
                    }
                }
                else{
                    emptyString += 1;
                }
            }
            if (newTimeStampLineNumber > 0 && playerItem) {
                [textView setTimeLineNumber:newTimeStampLineNumber];
                [textView setNeedsDisplay:YES];
            }
            else{
                [textView setTimeLineNumber:0];
            }
        }else{
            [textView setTimeLineNumber:0];
        }
    }else{
        [textView setTimeLineNumber:0];
    }
}

- (IBAction)startRepeatingTimer:sender {
    
    [self.repeatingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self selector:@selector(setTimestampLineNumber)
                                                    userInfo:nil repeats:YES];
    self.repeatingTimer = timer;
}

- (IBAction)stopRepeatingTimer:sender {
    [self.repeatingTimer invalidate];
    self.repeatingTimer = nil;
}


#pragma mark printing

- (IBAction)printThisDocument:(id)sender
{
    NSTextView *printTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 468, 648)];
    [printTextView setEditable:false];
    [[printTextView textStorage] setAttributedString:[textView attributedString]];
    NSPrintOperation *printOperation;
    printOperation = [NSPrintOperation printOperationWithView:printTextView];
    [printOperation runOperation];
}

@end



