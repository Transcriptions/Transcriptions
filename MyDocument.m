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

#import <SubRip/SubRip.h>
#import <SubRip/DTCoreTextConstants.h>

NSString * const	SRTDocumentType		= @"de.geheimwerk.subrip";

static void *TSCPlayerItemStatusContext = &TSCPlayerItemStatusContext;
static void *TSCPlayerRateContext = &TSCPlayerRateContext;
static void *TSCPlayerLayerReadyForDisplay = &TSCPlayerLayerReadyForDisplay;

@interface MyDocument ()

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
- (void)stopLoadingAnimationAndHandleError:(NSError *)error;

@end

@implementation MyDocument

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
	
	if (self) {
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
  [windowController.window setMovableByWindowBackground:YES];
  [windowController.window setContentBorderThickness:32.0 forEdge:NSMinYEdge];
  _playerView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
  if (_rtfSaveData) {
        [_textView.textStorage replaceCharactersInRange:NSMakeRange(0, _textView.string.length) withAttributedString:_rtfSaveData];
  }
  _textView.allowsUndo = YES;
  [_textView toggleRuler:self];
  _textView.delegate = self;
  _mTextField.delegate = self;
  _mainSplitView.delegate = self;
  _insertTableView.delegate = self;
  [_insertTableView registerForDraggedTypes:@[NSStringPboardType, NSRTFPboardType]];
  _infoPanel.minSize = _infoPanel.frame.size;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processTextEditing) name:NSTextDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openMovieFromDrag:) name:@"movieFileDrag" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createTimeStamp:) name:@"automaticTimestamp" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToTimeStamp:) name:@"aTimestampPressed" object:nil];
  _player = [[AVPlayer alloc] init];
  [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:TSCPlayerRateContext];
  [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:TSCPlayerItemStatusContext];
  [self updateTimestampLineNumber];
}




- (void)awakeFromNib
{
	self.autor  = _docAttributes[NSAuthorDocumentAttribute];
	self.copyright = _docAttributes[NSCopyrightDocumentAttribute];
	self.company = _docAttributes[NSCompanyDocumentAttribute];
	self.title = _docAttributes[NSTitleDocumentAttribute];
	self.subject = _docAttributes[NSSubjectDocumentAttribute];
	self.comment = _docAttributes[NSCommentDocumentAttribute];
	self.keywords = _docAttributes[NSKeywordsDocumentAttribute];
	
	if (_rtfSaveData.length > 0) {
		[_textView.textStorage replaceCharactersInRange:NSMakeRange(0, _textView.string.length) withAttributedString:_rtfSaveData];
	}
	
    NSTimeInterval autosaveInterval = 2.0;
    [NSDocumentController sharedDocumentController].autosavingDelay = autosaveInterval;
    _playerView.wantsLayer = YES;
    NSButton *closeButton = [_appWindow standardWindowButton:NSWindowCloseButton];
    NSView *titleBarView = closeButton.superview;
    NSButton* myHelpButton = [[NSButton alloc] initWithFrame:NSMakeRect(titleBarView.bounds.size.width - 30,titleBarView.bounds.origin.y, 25, 25)];
    myHelpButton.bezelStyle = NSHelpButtonBezelStyle;
    myHelpButton.title = @"";
    myHelpButton.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    myHelpButton.action = @selector(showHelp:);
    myHelpButton.target = [NSApplication sharedApplication];
    [titleBarView addSubview:myHelpButton];
    if (_comment.length > 0)
    {
        NSString* foundUrlString;
        if ([_comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound)
        {
         foundUrlString = [NSString stringWithString:[self getDataBetweenFromString:_comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21]];
        }
        if (foundUrlString.length > 0) {
            NSData *myData = [[NSData alloc] initWithBase64EncodedString:foundUrlString options:0];
            self.mediaFileBookmark = myData;
            if (_mediaFileBookmark)
            {
                NSError *error = nil;
                BOOL bookmarkDataIsStale;
                NSURL *bookmarkFileURL = nil;
                bookmarkFileURL = [NSURL
                                   URLByResolvingBookmarkData:_mediaFileBookmark
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
                else if(bookmarkFileURL.fileURL == YES)
                {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:bookmarkFileURL];
                    NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
                    NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:bookmarkFileURL.pathExtension];
                    typeImage.size = NSMakeSize(32, 32);
                    _mTextField.stringValue = bookmarkFileURL.lastPathComponent;
                    _typeImageView.image = typeImage;
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

- (void)dealloc
{
    [self.player pause];
    [self.player removeTimeObserver:self.timeObserverToken];
    self.timeObserverToken = nil;
	if (_player) {
		[self removeObserver:self forKeyPath:@"player.rate" context:TSCPlayerRateContext];
		[self removeObserver:self forKeyPath:@"player.currentItem.status" context:TSCPlayerItemStatusContext];
	}
    if (self.playerLayer)
        [self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay"];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
}


#pragma mark text edit processing
- (void)processTextEditing
{
    
}

- (void)textDidChange:(NSNotification *)notification
{
    [self updateChangeCount:NSChangeDone];
    _textView.needsDisplay = YES;
}


#pragma mark loadsave

- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrapper ofType:(NSString *)type error:(NSError **)outError
{
	if (!wrapper.regularFile)  return NO;
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	if ([workspace type:type conformsToType:(NSString *)kUTTypeRTF]) {
		return [self readFromRTFData:wrapper.regularFileContents
							   error:outError];
	}
	else if ([workspace type:type conformsToType:SRTDocumentType]) {
		return [self readFromSRTData:wrapper.regularFileContents
							   error:outError];
	}
	else {
		return [self readFromData:wrapper.regularFileContents
						   ofType:type
							error:outError];
	}
}

- (BOOL)readFromRTFData:(NSData *)data error:(NSError **)outError
{
	NSDictionary *docAttributes;
	_rtfSaveData = [[NSAttributedString alloc] initWithRTF:data documentAttributes:&docAttributes];
	_docAttributes = docAttributes;
	
    if (_keywords.count == 1) {
        NSString* firstObject = _keywords[0];
        if ([firstObject isEqualToString:@""]) {
            _keywords = nil;
        }
    }
	return YES;
}

- (BOOL)readFromSRTData:(NSData *)data error:(NSError **)outError
{
	SubRip *subRip = [[SubRip alloc] initWithData:data
										encoding:NSUTF8StringEncoding
										   error:outError];
	
	if (subRip == nil) {
		return NO;
	}
	
	CGFloat defaultSize = 13.0; // FIXME: Implement user defaults, also for _textView.
	NSString *defaultFontName = @"Helvetica";
	
	[subRip parseTagsWithOptions:@{
								   DTDefaultFontFamily : defaultFontName,
								   NSTextSizeMultiplierDocumentOption : @(defaultSize/12.0)
								   }];
	
	NSMutableArray *subtitleItems = subRip.subtitleItems;
	
	NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
	NSMutableString *string = text.mutableString;
	
	for (SubRipItem *subRipItem in subtitleItems) {
		CMTime startTime = subRipItem.startTime;
		CMTime endTime = subRipItem.endTime;

		NSAttributedString *itemText = subRipItem.attributedText;
		
		//NSRange insertionRange =
		[self insertTimeStampStringForCMTime:startTime
										  at:string.length
									intoText:text
									  string:string];

		[text appendAttributedString:itemText];
		
		NSRange insertionRange =
		[self insertTimeStampStringForCMTime:endTime
										  at:string.length
									intoText:text
									  string:string];
		
		NSRange insertionCursor = NSMakeRange(NSMaxRange(insertionRange), 0);
		[string replaceCharactersInRange:insertionCursor withString:@"\n"];
	}
	
	_rtfSaveData = text;
	self.fileType = (NSString *)kUTTypeRTF;
	
	return YES;
}

- (NSString *)getDataBetweenFromString:(NSString *)data leftString:(NSString *)leftData rightString:(NSString *)rightData leftOffset:(NSInteger)leftPos;
{
    NSInteger left, right;
    NSString *foundData;
    NSScanner *scanner=[NSScanner scannerWithString:data];
    [scanner scanUpToString:leftData intoString: nil];
    left = scanner.scanLocation;
    scanner.scanLocation = left + leftPos;
    [scanner scanUpToString:rightData intoString: nil];
    right = scanner.scanLocation + 1;
    left += leftPos;
    foundData = [NSString stringWithString:[data substringWithRange: NSMakeRange(left, (right - left) - 1)]];
    return foundData;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)type error:(NSError **)outError
{
   NSRange range = NSMakeRange(0, _textView.string.length);
    if (_autor.length <= 0) {
        _autor = @"";
    }
    if (_copyright.length <= 0) {
        _copyright = @"";
    }
    if (_company.length <= 0) {
        _company = @"";
    }
    if (_title.length <= 0) {
        _title = @"";
    }
    if (_subject.length <= 0) {
        _subject = @"";
    }
    if (_comment.length <= 0) {
        _comment = @"";
    }
    if (_keywords.count == 0) {
        _keywords = @[@""];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mediaFileAssoc"] boolValue] == YES)
    {
        if (_comment.length > 0)
        {
            if ([_comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound) {
                NSString* foundUrlString = [self getDataBetweenFromString:_comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21];
                if (foundUrlString.length > 0)
                {
                    NSString* toBeRemoved = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]",foundUrlString];
                    NSString* newComment = [_comment stringByReplacingOccurrencesOfString:toBeRemoved withString:@""];
                    _comment = newComment;
                }
            }
        }
        NSError *error = nil;
        BOOL bookmarkDataIsStale;
        NSURL *bookmarkFileURL = nil;
        bookmarkFileURL = [NSURL
                           URLByResolvingBookmarkData:_mediaFileBookmark
                           options:NSURLBookmarkResolutionWithSecurityScope
                           relativeToURL:nil
                           bookmarkDataIsStale:&bookmarkDataIsStale
                           error:&error];
        NSError* err;
        NSURL* fileUrl = [self urlOfCurrentlyPlayingInPlayer:self.player];
        if ([fileUrl.path compare:bookmarkFileURL.path] == NSOrderedSame && [fileUrl checkResourceIsReachableAndReturnError:&err] == YES && fileUrl.fileURL == YES)
        {
            NSString *utfString = [_mediaFileBookmark base64EncodedStringWithOptions:0];
            NSString* urlForComment = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]",utfString];
            NSString* commentString = [NSString stringWithFormat:@"%@%@", _comment, urlForComment];
            _comment = commentString;
            _commentTextField.stringValue = _comment;
        }
    }
	NSDictionary* docAttributes = @{
									NSAuthorDocumentAttribute: _autor,
									NSCopyrightDocumentAttribute: _copyright,
									NSCompanyDocumentAttribute: _company,
									NSTitleDocumentAttribute: _title,
									NSSubjectDocumentAttribute: _subject,
									NSCommentDocumentAttribute: _comment,
									NSKeywordsDocumentAttribute: _keywords
									};
	NSFileWrapper *wrapper = [[NSFileWrapper alloc]
							   initRegularFileWithContents:[_textView.textStorage RTFFromRange:range documentAttributes:docAttributes]];
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return wrapper;
}



#pragma mark media loading and unloading

- (IBAction)openMovieFile:(id)sender
{
    if (_mediaFileBookmark) {
        NSError *error = nil;
        BOOL bookmarkDataIsStale;
        NSURL *bookmarkFileURL = nil;
        bookmarkFileURL = [NSURL
                           URLByResolvingBookmarkData:_mediaFileBookmark
                           options:NSURLBookmarkResolutionWithSecurityScope
                           relativeToURL:nil
                           bookmarkDataIsStale:&bookmarkDataIsStale
                           error:&error];
        [bookmarkFileURL stopAccessingSecurityScopedResource];
    }
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    [panel beginSheetModalForWindow:_appWindow
                  completionHandler:^(NSInteger result) {
                      if (result == NSFileHandlingPanelOKButton) {
                          NSArray* filesToOpen = panel.URLs;
                          NSError *error = nil;
                          self.mediaFileBookmark = [filesToOpen[0]
                                          bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                          includingResourceValuesForKeys:nil
                                          relativeToURL:nil
                                          error:&error];
                          NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[filesToOpen[0] pathExtension]];
                          typeImage.size = NSMakeSize(32, 32);
                          _mTextField.stringValue = [filesToOpen[0] lastPathComponent];
                          _typeImageView.image = typeImage;
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
	NSString *URLString;
	if ((URLString = _URLTextField.stringValue) != nil)
	{
		NSURL *movieURL = [NSURL URLWithString:URLString];
		[NSApp endSheet:_URLPanel];
		NSImage *typeImage = [[NSWorkspace sharedWorkspace] iconForFileType:URLString.pathExtension];
		typeImage.size = NSMakeSize(32, 32);
		_mTextField.stringValue = URLString.lastPathComponent;
		_typeImageView.image = typeImage;
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
//	typeImage.size = NSMakeSize(32, 32);
//	mTextField.stringValue = [URLString lastPathComponent];
//	typeImageView.image = typeImage;
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
    if (!asset.playable || asset.hasProtectedContent)
    {
        [self stopLoadingAnimationAndHandleError:nil];
        return;
    }
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0)
    {
        AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        newPlayerLayer.frame = _playerView.layer.bounds;
        newPlayerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        newPlayerLayer.hidden = YES;
        [_playerView.layer addSublayer:newPlayerLayer];
        self.playerLayer = newPlayerLayer;
        [self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:TSCPlayerLayerReadyForDisplay];
    }
    else
    {
        [self stopLoadingAnimationAndHandleError:nil];
        _noVideoImage.hidden = NO;
    }
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        _timeSlider.doubleValue = CMTimeGetSeconds(time);
        _mTimeDisplay.stringValue = [self CMTimeAsString:time];
    }];
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
                [self stopLoadingAnimationAndHandleError:self.player.currentItem.error];
                break;
        }
        
        _playPauseButton.enabled = enable;
        _fastForwardButton.enabled = enable;
        _rewindButton.enabled = enable;
    }
    else if (context == TSCPlayerRateContext)
    {
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        if (rate == 0.f)
        {
            //[[self playPauseButton] setTitle:@"Play"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setFloat:rate forKey:@"currentRate"];
            //[[self playPauseButton] setTitle:@"Pause"];
        }
    }
    else if (context == TSCPlayerLayerReadyForDisplay)
    {
        if ([change[NSKeyValueChangeNewKey] boolValue] == YES)
        {
            [self stopLoadingAnimationAndHandleError:nil];
            [self.playerLayer setHidden:NO];
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
            modalForWindow:self.windowForSheet
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
	return [NSString stringWithFormat:@"%02lu:%02lu:%02lu.%02lld" , (unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds, tenthSeconds];
}


+ (NSSet *)keyPathsForValuesAffectingDuration
{
    return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (double)duration
{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
        return CMTimeGetSeconds(playerItem.asset.duration);
    else
        return 0.f;
}

- (double)currentTime
{
    return CMTimeGetSeconds([self.player currentTime]);
}

- (void)setCurrentTime:(double)time
{
    [self.player seekToTime:CMTimeMakeWithSeconds(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
	[self updateTimestampLineNumber];
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
        AVPlayerItem *playerItem = self.player.currentItem;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay)
        {
            _mDuration.stringValue = [self CMTimeAsString:playerItem.asset.duration];
        }
    }
}

- (float)volume
{
    return self.player.volume;
}

- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

- (void)setNormalSizeDisplay
{
    NSMutableString *sizeString = [NSMutableString string];
    NSSize movieSize;
    NSArray* videoAssets = [self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoAssets.count != 0)
    {
    movieSize = [videoAssets[0] naturalSize];
    [sizeString appendFormat:@"%.0f", movieSize.width];
    [sizeString appendString:@" x "];
    [sizeString appendFormat:@"%.0f", movieSize.height];
    _movieNormalSize.stringValue = sizeString;
    }
    else{
        _movieNormalSize.stringValue = @"";
    }
}

- (void)setCurrentSizeDisplay
{
	{
		NSSize mCurrentSize;
		mCurrentSize = _playerView.bounds.size;
		NSMutableString *sizeString = [NSMutableString string];
		
		[sizeString appendFormat:@"%.0f", mCurrentSize.width];
		[sizeString appendString:@" x "];
		[sizeString appendFormat:@"%.0f", mCurrentSize.height];
		
		_movieCurrentSize.stringValue = sizeString;
	}
}

- (void)rePlay:(id)sender
{
	 if (self.player.currentItem)
    {
        CMTime currentTime = [self.player currentTime];
        CMTime timeToAdd   = CMTimeMakeWithSeconds(_replaySlider.intValue, 1);
        CMTime resultTime  = CMTimeSubtract(currentTime,timeToAdd);
        [self.player seekToTime:resultTime];
        float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
        [self.player play];
        self.player.rate = myRate;
        [self updateTimestampLineNumber];
    }
}

- (IBAction)playPauseToggle:(id)sender
{
    if (self.player.rate == 0.f)
    {
        if (self.currentTime == self.duration)
        {
            self.currentTime = 0.f;
        }
        float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
        [self.player play];
        self.player.rate = myRate;
        [self updateTimestampLineNumber];
    }
    else
    {
        [self.player pause];
    }
}


- (IBAction)fastForward:(id)sender
{
    if (self.player.rate < 2.f)
    {
        self.player.rate = 2.f;
    }
    else
    {
        self.player.rate = self.player.rate + 2.f;
    }
}

- (IBAction)rewind:(id)sender
{
    if (self.player.rate > -2.f)
    {
        self.player.rate = -2.f;
    }
    else
    {
        self.player.rate = self.player.rate - 2.f;
    }
}


#pragma mark timeStamp methods

- (NSDictionary *)timeStampAttributes
{
	return @{
			 NSForegroundColorAttributeName: [NSColor grayColor],
			 //NSFontAttributeName: [NSFont systemFontOfSize:12], // We just disable this and use the current default size.
			 };
}

- (NSRange)insertTimeStampStringForCMTime:(CMTime)time
									   at:(NSUInteger)insertionLocation
								 intoText:(NSMutableAttributedString *)text
								   string:(NSMutableString *)string
{
	NSRange insertionCursor = NSMakeRange(insertionLocation, 0);
	NSRange insertionRange = insertionCursor;
	
	NSString *timeString = [self CMTimeAsString:time];
	
	NSString * const prefix = @" #";
	const NSUInteger prefixLength = 2;
	const NSUInteger prefixSpaceOffset = 1;
	
	NSString * const suffix = @"# ";
	const NSUInteger suffixLength = 2;
	const NSUInteger suffixSpaceOffset = 1;
	
	[string replaceCharactersInRange:insertionCursor withString:prefix];		insertionCursor.location += prefixLength;
	[string replaceCharactersInRange:insertionCursor withString:timeString];	insertionCursor.location += timeString.length;
	[string replaceCharactersInRange:insertionCursor withString:suffix];		insertionCursor.location += suffixLength;
	
	insertionRange.length = insertionCursor.location - insertionRange.location;
	
	NSRange attributesRange = insertionRange;
	insertionRange.location += prefixSpaceOffset;
	insertionRange.length -= prefixSpaceOffset + suffixSpaceOffset;
	[text addAttributes:self.timeStampAttributes range:attributesRange];
	
	return insertionRange;
}

- (void)createTimeStamp:(id)sender
{
	if (self.player.currentItem) {
		NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
		NSMutableString *string = text.mutableString;
		CMTime time = self.player.currentTime;
		
		NSRange textRange =
		[self insertTimeStampStringForCMTime:time
										  at:0
									intoText:text
									  string:string];
		NSRange insertionCursor = NSMakeRange(NSMaxRange(textRange), 0);
		
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue] == YES) {
			NSString * const newline = @"\n";
			const NSUInteger newlineLength = 1;
			
			[string replaceCharactersInRange:insertionCursor withString:newline];
			textRange.length += newlineLength;
		}
		
		NSUInteger insertionLocation = NSMaxRange(_textView.selectedRange); // Define insertion point as the location at the end of the current selection.
		NSRange insertionRange = NSMakeRange(insertionLocation, 0);

		[_textView insertText:text replacementRange:insertionRange]; // This also enables undo support.
		
        [self updateTimestampLineNumber];
	}
}

- (void)jumpToTimeStamp:(NSNotification *)note
{
    NSButton* tsButton = note.object;
    if (tsButton.window == _appWindow) {
        NSString* timestampTimeString = tsButton.title;
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"timestampReplay"] boolValue] == YES )
        {
            CMTime timeToAdd   = CMTimeMakeWithSeconds(_replaySlider.intValue, 1);
            CMTime resultTime  = CMTimeSubtract([self cmtimeForTimeStampString:timestampTimeString],timeToAdd);
            [self.player seekToTime:resultTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            float myRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"currentRate"];
            [self.player play];
            (self.player).rate = myRate;
        }
        else
        {
            [self.player seekToTime:[self cmtimeForTimeStampString:timestampTimeString] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        }
        [self updateTimestampLineNumber];
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
	if (!_HUDPanel.visible){
		if (_HUDPanel.contentView.subviews.count == 0){
			
			NSRect initialFrame = [self newFrameForNewHUD:_HUDPanel contentView:_firstSubView];
			_HUDPanel.contentSize = _firstSubView.frame.size;
			_HUDPanel.title = @"Media Controls";
			[_HUDPanel.contentView addSubview:_firstSubView];
			[_HUDPanel.contentView setWantsLayer:YES];
			_HUDPanel.minSize = initialFrame.size;
		}else if ([_HUDPanel.contentView.subviews containsObject:_secondSubView])
		{
			NSRect changeAfterOpenFrame = [self newFrameForNewHUD:_HUDPanel contentView:_firstSubView];
			[NSAnimationContext beginGrouping];

			_HUDPanel.title = @"Media Controls";
			[[_HUDPanel.contentView animator] replaceSubview:_secondSubView with:_firstSubView];
			[[_HUDPanel animator] setFrame:changeAfterOpenFrame display:YES];
			
			[NSAnimationContext endGrouping];
			_HUDPanel.minSize = changeAfterOpenFrame.size;

		}
		
		[_HUDPanel orderFront:sender];
	
		_infoButton.action = @selector(closeHUDPanel:);
	}else{
		[self closeHUDPanel:self];
	}
}

- (void)closeHUDPanel:(id)sender
{
	if (_HUDPanel.visible){
		[_HUDPanel orderOut:sender];
		_infoButton.action = @selector(openHUDPanel:);
	}else{
		[self openHUDPanel:self];
	}
}

- (void)showMediaInfo:(id)sender
{
	NSRect newFrame = [self newFrameForNewHUD:_HUDPanel contentView:_secondSubView];
	
	[NSAnimationContext beginGrouping];
	
	_HUDPanel.title = @"Media Information";

	[[_HUDPanel.contentView animator] replaceSubview:_firstSubView with:_secondSubView];
	[[_HUDPanel animator] setFrame:newFrame display:YES];

	[NSAnimationContext endGrouping];
	_HUDPanel.minSize = newFrame.size;
	
	if (self.player.currentItem){
		[self setNormalSizeDisplay];
		[self setCurrentSizeDisplay];
		[self setDurationDisplay];
		_movieFileField.stringValue = [self urlOfCurrentlyPlayingInPlayer:self.player].absoluteString;
	}
}

- (NSURL *)urlOfCurrentlyPlayingInPlayer:(AVPlayer *)player {
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    return ((AVURLAsset *)currentPlayerAsset).URL;
}

- (void)showMediaControls:(id)sender
{
	NSRect firstFrame = [self newFrameForNewHUD:_HUDPanel contentView:_firstSubView];
	[NSAnimationContext beginGrouping];
	_HUDPanel.title = @"Media Controls";
	[[_HUDPanel.contentView animator] replaceSubview:_secondSubView with:_firstSubView];
	[[_HUDPanel animator] setFrame:firstFrame display:YES];
	[NSAnimationContext endGrouping];
	_HUDPanel.minSize = firstFrame.size;
}

-(NSRect)newFrameForNewHUD:(NSPanel*)panel contentView:(NSView *)view {
    
	NSRect newFrameRect = [panel frameRectForContentRect:view.frame];
    NSRect oldFrameRect = panel.frame;
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    NSRect frame = panel.frame;
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
	NSArray* charArray = _textView.textStorage.characters;
	NSString* charRepresentation = [NSString stringWithFormat:@"%lu", (unsigned long)charArray.count];
	//see:http://www.cocoadev.com/index.pl?NSStringCategory 
	NSMutableCharacterSet* wordSet = [NSMutableCharacterSet letterCharacterSet];
	[wordSet addCharactersInString:@"-"];
	NSScanner* scanner      = [NSScanner scannerWithString:_textView.string];
	NSMutableArray* wordArray      = [NSMutableArray array];
	scanner.charactersToBeSkipped = wordSet.invertedSet;
	while (!scanner.atEnd)
	{
		NSString* destination = [NSString string];
		
		if ([scanner scanCharactersFromSet:wordSet intoString:&destination])
		{
			[wordArray addObject:[NSString stringWithString:destination]];
		}
	}
	NSString* wordRepresentation = [NSString stringWithFormat:@"%lu",(unsigned long)[[wordArray copy] count]];
	NSArray *lines = [_textView.string componentsSeparatedByString:@"\n"];	
	int i;
	int emptyString = 0;
	int parNumber = 0;
	NSString *s = [NSString stringWithFormat:@"%i", parNumber];
	for (i=0;i<lines.count;i++) {
			if ([lines[i] length] > 0){
					parNumber = (i + 1) - emptyString;
					s = [NSString stringWithFormat:@"%i", parNumber];
				}
			else{
				emptyString += 1;
			}
	}
	_paragraphTextField.stringValue = s;
	_wordTextField.stringValue = wordRepresentation;
	_charTextField.stringValue = charRepresentation;
	[self showInfoSheet:_appWindow];
}


- (void)showInfoSheet: (NSWindow *)window
{
    [self.windowForSheet beginSheet:_infoPanel completionHandler:^(NSModalResponse returnCode) {
		[_infoPanel orderOut:self];
	}];
}

- (void)closeInfoSheet: (id)sender
{
    [self.windowForSheet endSheet:_infoPanel];
}


- (void)startURLSheet:(id)sender
{
	[self showURLSheet:_appWindow];
}


- (void)showURLSheet: (NSWindow *)window
{
	[self.windowForSheet beginSheet:_URLPanel completionHandler:^(NSModalResponse returnCode) {
		[_URLPanel orderOut:self];
	}];
	// FIXME: Is this still necessary? Looks like a hack. ;)
	_URLPanel.minSize = _URLPanel.frame.size;
	_URLPanel.maxSize = _URLPanel.frame.size;
}

- (void)closeURLSheet: (id)sender
{
	[self.windowForSheet endSheet:_URLPanel];
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

- (void)updateTimestampLineNumber
{
    NSString* theString = _textView.string;
    NSMutableArray* myTimeValueArray = [NSMutableArray arrayWithCapacity:10];
    if (theString.length != 0)
    {
        NSScanner* lineScanner = [NSScanner scannerWithString:theString];
        NSCharacterSet* rauteSet = [NSCharacterSet characterSetWithCharactersInString:@"#"];
        NSString* tscTimeValue;
        NSString* rauteA;
        NSString* rauteB;
        while (lineScanner.atEnd == NO && lineScanner.scanLocation != NSNotFound)
        {
            BOOL scanned;
            if([[theString substringFromIndex:lineScanner.scanLocation] compare:@"#"] != NSOrderedSame)
            {[lineScanner scanUpToCharactersFromSet:rauteSet intoString:NULL];}
            scanned = [lineScanner scanString:@"#" intoString:&rauteA] &&
            [lineScanner scanUpToCharactersFromSet:rauteSet intoString:&tscTimeValue] &&
            [lineScanner scanString:@"#" intoString:&rauteB];
            if (scanned && tscTimeValue.length > 0){
                if(myTimeValueArray.count > 1)
                {
                    [myTimeValueArray removeObjectIdenticalTo:tscTimeValue];
                }
                [myTimeValueArray addObject:tscTimeValue];
            }
        }
    }
    AVPlayerItem *playerItem = self.player.currentItem;
    [myTimeValueArray addObject:[self CMTimeAsString:CMTimeAbsoluteValue(playerItem.asset.duration)]];
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
    for (int x = 0; x < sortedValues.count; x++) {
        CMTime timeStampTime = [self cmtimeForTimeStampString:sortedValues[x]];
        CMTime timeStampTimeNext;
        if (x < sortedValues.count - 1)
        {
            timeStampTimeNext   = [self cmtimeForTimeStampString:sortedValues[x + 1]];
        }else{
            timeStampTimeNext   = CMTimeAbsoluteValue(playerItem.asset.duration);
        }
        CMTime currentTime = CMTimeAbsoluteValue([self.player currentTime]);
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
        CMTime currentTime = CMTimeAbsoluteValue([self.player currentTime]);
        int32_t comparison = CMTimeCompare(comparisonTimeStampTime, currentTime);
        if (comparison <= 0) {
            NSArray* lines = [self->_textView.string componentsSeparatedByString:@"\n"];
            int newTimeStampLineNumber = 0;
            int i;
            int emptyString = 0;
            for (i=0;i<lines.count;i++) {
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
                _textView.timeLineNumber = newTimeStampLineNumber;
                _textView.needsDisplay = YES;
            }
            else{
                _textView.timeLineNumber = 0;
            }
        }else{
            _textView.timeLineNumber = 0;
        }
    }else{
        _textView.timeLineNumber = 0;
    }
}

#pragma mark printing

- (IBAction)printThisDocument:(id)sender
{
    NSTextView *printTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 468, 648)];
    printTextView.editable = false;
    [printTextView.textStorage setAttributedString:_textView.attributedString];
    NSPrintOperation *printOperation;
    printOperation = [NSPrintOperation printOperationWithView:printTextView];
    [printOperation runOperation];
}

@end



