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


#import "TSCDocument.h"
#include <unistd.h>

#import <SubRip/SubRip.h>
#import <SubRip/DTCoreTextConstants.h>

#import "JXCMTimeStringTransformer.h"

#import "AVPlayer+TSCPlay.h"
#import "NSString+TSCTimeStamp.h"
#import "NSString+TSCWhitespace.h"
#import "TSCTimeSourceRange.h"


NSString * const	SRTDocumentType		= @"org.niltsh.mplayerx-subrip";
NSString * const	TSCPlayerItemStatusKeyPath			= @"status";

static void *TSCPlayerItemStatusContext = &TSCPlayerItemStatusContext;
static void *TSCPlayerRateContext = &TSCPlayerRateContext;
static void *TSCPlayerLayerReadyForDisplay = &TSCPlayerLayerReadyForDisplay;
static void *TSCPlayerItemReadyToPlay = &TSCPlayerItemReadyToPlay;

NSString * const	TSCErrorDomain		= @"com.davidhas.Transcriptions.error";


@interface TSCDocument ()

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
- (void)stopLoadingAnimationAndHandleError:(NSError *)error;

@end

@implementation TSCDocument

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
	return @"TSCDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];
	
	[windowController.window setMovableByWindowBackground:YES];
	[windowController.window setContentBorderThickness:32.0
											   forEdge:NSMinYEdge];
	
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createAutomaticTimeStamp:) name:@"automaticTimestamp" object:nil];
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
	
	if (_keywords.count == 1) {
		NSString *firstObject = _keywords[0];
		if ([firstObject isEqualToString:@""]) {
			_keywords = nil;
		}
	}
	
	if (_rtfSaveData.length > 0) {
		[_textView.textStorage replaceCharactersInRange:NSMakeRange(0, _textView.string.length) withAttributedString:_rtfSaveData];
	}
	
	NSTimeInterval autosaveInterval = 2.0;
	NSDocumentController.sharedDocumentController.autosavingDelay = autosaveInterval;
	
	_playerView.wantsLayer = YES;
	
	NSButton *closeButton = [_appWindow standardWindowButton:NSWindowCloseButton];
	NSView *titleBarView = closeButton.superview;
	
	NSButton *myHelpButton = [[NSButton alloc] initWithFrame:NSMakeRect(titleBarView.bounds.size.width - 30, titleBarView.bounds.origin.y, 25, 25)];
	myHelpButton.bezelStyle = NSHelpButtonBezelStyle;
	myHelpButton.title = @"";
	myHelpButton.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
	myHelpButton.action = @selector(showHelp:);
	myHelpButton.target = [NSApplication sharedApplication];
	
	[titleBarView addSubview:myHelpButton];
	
	if (_comment.length > 0) {
		NSString *foundURLString;
		if ([_comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound) {
			foundURLString = [NSString stringWithString:[self getDataBetweenFromString:_comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21]];
		}
		
		if (foundURLString.length > 0) {
			NSData *myData = [[NSData alloc] initWithBase64EncodedString:foundURLString options:0];
			self.mediaFileBookmark = myData;
			if (_mediaFileBookmark) {
				NSError *error = nil;
				
				NSURL *bookmarkFileURL =
				[NSURL URLByResolvingBookmarkData:_mediaFileBookmark
										  options:NSURLBookmarkResolutionWithSecurityScope
									relativeToURL:nil
							  bookmarkDataIsStale:NULL
											error:&error];
				
				NSError *err;
				if ([bookmarkFileURL checkResourceIsReachableAndReturnError:&err] == NO) {
					NSLog(@"%@", err);

					NSAlert *alert = [NSAlert alertWithError:err];
					[alert beginSheetModalForWindow:self.windowForSheet
								  completionHandler:^(NSModalResponse returnCode) {
								  }];
				}
				else if (bookmarkFileURL.fileURL) {
					[self loadAndSetupAssetWithURL:bookmarkFileURL];
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

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrapper ofType:(NSString *)type error:(NSError **)outError
{
	if (!wrapper.regularFile)  return NO;
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	if ([workspace type:type conformsToType:(NSString *)kUTTypeRTF]) {
		return [self readFromRTFData:wrapper.regularFileContents
							   error:outError];
	}
	else if ([workspace type:type conformsToType:SRTDocumentType]) {
		BOOL result =
		[self readFromSRTData:wrapper.regularFileContents
							   error:outError];
		
		if (result) {
			NSURL *fileURL = self.fileURL;
			fileURL = [fileURL URLByDeletingPathExtension];
			fileURL = [fileURL URLByAppendingPathExtension:@"rtf"];
			self.fileURL = fileURL;
			
			self.fileType = (NSString *)kUTTypeRTF;
		}
		
		return result;
	}
	else {
		return NO;
	}
}

- (BOOL)readFromRTFData:(NSData *)data error:(NSError **)outError
{
	NSDictionary *docAttributes;
	NSDictionary *docReadOptions = @{
									 NSDocumentTypeDocumentOption: NSRTFTextDocumentType
									 };
	
	_rtfSaveData = [[NSAttributedString alloc] initWithData:data
													options:docReadOptions
										 documentAttributes:&docAttributes
													  error:outError];
	if (!_rtfSaveData) {
		return NO;
	}
	
	_docAttributes = docAttributes;
	
	return YES;
}

void insertNewlineAfterRange(NSMutableString *string, NSRange insertionRange)
{
	NSRange insertionCursor = NSMakeRange(NSMaxRange(insertionRange), 0);
	[string replaceCharactersInRange:insertionCursor withString:@"\n"];
}

- (BOOL)readFromSRTData:(NSData *)data error:(NSError **)outError
{
	// TODO: Add UI for mergeConsecutiveIdenticalTimeStamps (merge consecutive time stamps within a given distance).
	// TODO: Add UI for timeStampsOnSeparateLines (forcing time stamps onto their own row instead of having them inline).
	BOOL mergeConsecutiveTimeStamps = NO;
	BOOL mergeIdenticalTimeStampsOnly = YES;
	CMTime mergeDistance = CMTimeMake(5, 100);
	CMTime mergeRangeDuration = CMTimeMultiply(mergeDistance, 2);
	
	BOOL timeStampsOnSeparateLines = NO;
	
	NSStringEncoding encoding =
	[NSString stringEncodingForData:data
					encodingOptions:nil
					convertedString:NULL
				usedLossyConversion:NULL];
	
	if ((encoding == 0) ||
		(encoding == NSASCIIStringEncoding)) {
		encoding = NSUTF8StringEncoding;
	}
	
	SubRip *subRip = [[SubRip alloc] initWithData:data
										 encoding:encoding
											error:outError];
	
	if (subRip == nil) {
		return NO;
	}
	
	// FIXME: store detected encoding in file metadata.
	_detectedImportTextEncoding = encoding;
	
	CGFloat defaultSize = 13.0; // FIXME: Implement user defaults, also for _textView.
	NSString *defaultFontName = @"Helvetica";
	
	[subRip parseTagsWithOptions:@{
								   DTDefaultFontFamily : defaultFontName,
								   NSTextSizeMultiplierDocumentOption : @(defaultSize/12.0)
								   }];
	
	NSMutableArray *subtitleItems = subRip.subtitleItems;
	
	NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
	NSMutableString *string = text.mutableString;
	
	CMTime previousEndTime = kCMTimeInvalid;
	CMTimeRange mergeTimeRange = CMTimeRangeMake(kCMTimeInvalid, mergeRangeDuration);
	
	const NSRange invalidRange = NSMakeRange(NSNotFound, 0);
	NSRange previousEndTimeStampRange = invalidRange;
	
	for (SubRipItem *subRipItem in subtitleItems) {
		CMTime startTime = subRipItem.startTime;
		CMTime endTime = subRipItem.endTime;
		
		BOOL insertStartTime = YES;
		BOOL insertNewlineAfterStartTime = timeStampsOnSeparateLines;
		
		if (mergeConsecutiveTimeStamps) {
			if (!CMTIME_IS_INVALID(previousEndTime)) {
				if (mergeIdenticalTimeStampsOnly &&
					CMTIME_COMPARE_INLINE(previousEndTime, ==, startTime)) {
					insertStartTime = NO;
				}
				else if (!mergeIdenticalTimeStampsOnly) {
					mergeTimeRange.start = CMTimeSubtract(startTime, mergeDistance);
					if (CMTimeRangeContainsTime(mergeTimeRange, previousEndTime)) {
						[string replaceCharactersInRange:previousEndTimeStampRange withString:@""];
						
						CMTime centerTimeRangeDuration = CMTimeSubtract(startTime, previousEndTime);
						CMTime centerTimeDistance = CMTimeMultiplyByRatio(centerTimeRangeDuration, 1, 2);
						CMTime centerTime = CMTimeAdd(startTime, centerTimeDistance);
						
						startTime = centerTime;
						
						insertStartTime = YES;
						insertNewlineAfterStartTime = YES;
					}
				}
			}
		}
		
		NSAttributedString *itemText = subRipItem.attributedText;
		
		NSRange insertionRange;
		
		if (insertStartTime) {
			insertionRange =
			[self insertTimeStampStringForCMTime:startTime
											  at:string.length
										intoText:text
										  string:string
									prependSpace:NO
									 appendSpace:YES
								  timeStampRange:NULL];
			
			if (insertNewlineAfterStartTime) {
				insertNewlineAfterRange(string, insertionRange);
			}
		}
		
		[text appendAttributedString:itemText];
		
		if (timeStampsOnSeparateLines) {
			insertionRange.location = string.length;
			insertionRange.length = 0;
			insertNewlineAfterRange(string, insertionRange);
		}
		
		insertionRange =
		[self insertTimeStampStringForCMTime:endTime
										  at:string.length
									intoText:text
									  string:string
								prependSpace:!timeStampsOnSeparateLines
								 appendSpace:YES
							  timeStampRange:NULL];
		
		insertNewlineAfterRange(string, insertionRange);
		
		if (mergeConsecutiveTimeStamps) {
			previousEndTime = endTime;
			
			const NSUInteger newlineLength = 1;
			insertionRange.length += newlineLength;
			previousEndTimeStampRange = insertionRange;
		}
	}
	
	_rtfSaveData = text;
	
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

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
	NSArray *writableTypes = [super writableTypesForSaveOperation:saveOperation];
	
	switch (saveOperation) {
		case NSSaveToOperation:
		{
			NSMutableArray *exportableTypes = [writableTypes mutableCopy];
			[exportableTypes removeObject:(NSString *)kUTTypeRTF];
			return exportableTypes;
			break;
		}
		default:
		{
			return writableTypes;
			break;
		}
	}
	
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
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	if ([workspace type:type conformsToType:SRTDocumentType]) {
		return [self SRTFileWrapperForTimeStampedText:_textView.textStorage
												error:outError];
	}
	else if ([workspace type:type conformsToType:(NSString *)kUTTypeRTF]) {
		// Continue onwards.
	}
	else {
		return nil;
	}
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mediaFileAssoc"] boolValue] == YES) {
		if (_comment.length > 0) {
			if ([_comment rangeOfString:@"[[associatedMediaURL:"].location != NSNotFound) {
				NSString *foundUrlString = [self getDataBetweenFromString:_comment leftString:@"[[associatedMediaURL:" rightString:@"]]" leftOffset:21];
				if (foundUrlString.length > 0) {
					NSString *toBeRemoved = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]", foundUrlString];
					NSString *newComment = [_comment stringByReplacingOccurrencesOfString:toBeRemoved withString:@""];
					_comment = newComment;
				}
			}
		}
		
		NSError *error = nil;
		NSURL *bookmarkFileURL = nil;
		bookmarkFileURL = [NSURL URLByResolvingBookmarkData:_mediaFileBookmark
													options:NSURLBookmarkResolutionWithSecurityScope
											  relativeToURL:nil
										bookmarkDataIsStale:NULL
													  error:&error];
		NSError *err;
		NSURL *fileUrl = [self URLCurrentlyPlayingInPlayer:self.player];
		if ([fileUrl.absoluteString isEqualToString:bookmarkFileURL.absoluteString] &&
			([fileUrl checkResourceIsReachableAndReturnError:&err] == YES) &&
			(fileUrl.fileURL == YES)) {
			NSString *utfString = [_mediaFileBookmark base64EncodedStringWithOptions:0];
			NSString *urlForComment = [NSString stringWithFormat:@"[[associatedMediaURL:%@]]", utfString];
			NSString *commentString = [NSString stringWithFormat:@"%@%@", _comment, urlForComment];
			_comment = commentString;
			_commentTextField.stringValue = _comment;
		}
	}
	
	NSDictionary *docAttributes = @{
									NSAuthorDocumentAttribute: _autor,
									NSCopyrightDocumentAttribute: _copyright,
									NSCompanyDocumentAttribute: _company,
									NSTitleDocumentAttribute: _title,
									NSSubjectDocumentAttribute: _subject,
									NSCommentDocumentAttribute: _comment,
									NSKeywordsDocumentAttribute: _keywords
									};
	
	NSData *RTFData = [_textView.textStorage RTFFromRange:range documentAttributes:docAttributes];
	if (!RTFData) {
		return nil;
	}
	
	NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:RTFData];
	
	if (!wrapper && (outError != NULL)) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	
	return wrapper;
}

- (NSFileWrapper *)SRTFileWrapperForTimeStampedText:(NSAttributedString *)text
											  error:(NSError **)outError;
{
	NSString *string = text.string;
	
	NSMutableArray *subtitleItems = [NSMutableArray array];
	
	// FIXME: Check that the time stamps in the text are sorted ascending. Display error with the first offending line otherwise.
	
	const NSRange fullRange = NSMakeRange(0, string.length);
	
	__block CMTime previousTime = kCMTimeZero;
	__block NSRange previousRange = NSMakeRange(0, 0);
	
	TSCTimeStampEnumerationOptions options = TSCTimeStampEnumerationStringNotRequired;
	
	[string enumerateTimeStampsInRange:fullRange
							   options:options
							usingBlock:
	 ^(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop) {
		 NSUInteger subtitleStart = NSMaxRange(previousRange);
		 NSUInteger subtitleEnd = timeStampRange.location;
		 NSRange subtitleRange = NSMakeRange(subtitleStart, subtitleEnd - subtitleStart);
		 
		 if (![string isBlankRange:subtitleRange]) {
			 SubRipItem *subRipItem = [[SubRipItem alloc] init];
			 
			 NSMutableAttributedString *currentText = [[text attributedSubstringFromRange:subtitleRange] mutableCopy];
			 NSMutableString *currentMutableString = currentText.mutableString;
			 CFStringTrimWhitespace((__bridge CFMutableStringRef)currentMutableString);
			 
			 subRipItem.attributedText = currentText;
			 
			 subRipItem.startTime = previousTime;
			 subRipItem.endTime = time;
			 
			 [subtitleItems addObject:subRipItem];
		 }
		 
		 previousTime = time;
		 previousRange = timeStampRange;
	 }];
	
	SubRip *subRip = [[SubRip alloc] initWithSubtitleItems:subtitleItems];
	
	NSString *subRipString = [subRip srtStringWithLineBreaksInSubtitlesAllowed:YES];
	
	NSData *SRTData = nil;
	
	NSStringEncoding encoding = _detectedImportTextEncoding ?: NSUTF8StringEncoding;
	
	if (![subRipString canBeConvertedToEncoding:encoding]) {
		encoding = NSUTF8StringEncoding;
	}
	
	SRTData = [subRipString dataUsingEncoding:encoding
						 allowLossyConversion:NO];
	
	if (!SRTData) {
		if (outError) {
			NSString *description =
			[NSString stringWithFormat:NSLocalizedString(@"The string couldn’t be converted to the text encoding %@.", @""),
			 [NSString localizedNameOfStringEncoding:encoding]];
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: description,
									   NSStringEncodingErrorKey: @(encoding)
									   };
			*outError = [NSError errorWithDomain:TSCErrorDomain
											code:TSCErrorWriteInapplicableStringEncodingError
										userInfo:userInfo];
		}
		
		return nil;
	}
	
	NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:SRTData];
	
	if (!wrapper && (outError != NULL)) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	
	return wrapper;
}

- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	NSNumber *isWritableNum;
	BOOL retrieved = [self.fileURL getResourceValue:&isWritableNum
											 forKey:NSURLIsWritableKey
											  error:NULL];
	
	if (!retrieved ||
		(retrieved &&
		 !isWritableNum.boolValue)) {
		[self runModalSavePanelForSaveOperation:NSSaveAsOperation
									   delegate:delegate
								didSaveSelector:didSaveSelector
									contextInfo:contextInfo];
	}
	else {
		[super saveDocumentWithDelegate:delegate
						didSaveSelector:didSaveSelector
							contextInfo:contextInfo];
	}
}

// From TextEdit sample code.
// For details, see:
// https://forums.developer.apple.com/message/92795#92795
// TL;DR: Fix for “When I manually do a Command+S to save the document, thereafter autosaving stops working.”
/* When we save, we send a notification so that views that are currently coalescing undo actions can break that. This is done for two reasons, one technical and the other HI oriented.
 
 Firstly, since the dirty state tracking is based on undo, for a coalesced set of changes that span over a save operation, the changes that occur between the save and the next time the undo coalescing stops will not mark the document as dirty. Secondly, allowing the user to undo back to the precise point of a save is good UI.
 
 In addition we overwrite this method as a way to tell that the document has been saved successfully. If so, we set the save time parameters in the document.
 */
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *error))handler {
	// Note that we do the breakUndoCoalescing call even during autosave, which means the user's undo of long typing will take them back to the last spot an autosave occured. This might seem confusing, and a more elaborate solution may be possible (cause an autosave without having to breakUndoCoalescing), but since this change is coming late in Leopard, we decided to go with the lower risk fix.
	//[self.windowControllers makeObjectsPerformSelector:@selector(breakUndoCoalescing)];
	[self breakUndoCoalescing];

	[self performAsynchronousFileAccessUsingBlock:^(void (^fileAccessCompletionHandler)(void)) {
		//currentSaveOperation = saveOperation;
		[super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error) {
			//self.encodingForSaving = NoStringEncoding;   // This is set during prepareSavePanel:, but should be cleared for future save operation without save panel
			fileAccessCompletionHandler();
			handler(error);
		}];
	}];
	
}

- (void)breakUndoCoalescing
{
	[_textView breakUndoCoalescing];
}


#pragma mark media loading and unloading

- (IBAction)openMovieFile:(id)sender
{
	NSURL *fileURL = nil;
	
	if (_mediaFileBookmark) {
		NSError *error = nil;
		BOOL bookmarkDataIsStale;
		fileURL =
		[NSURL URLByResolvingBookmarkData:_mediaFileBookmark
								  options:NSURLBookmarkResolutionWithSecurityScope
							relativeToURL:nil
					  bookmarkDataIsStale:&bookmarkDataIsStale
									error:&error];
	}
	
	// FIXME: Use the panel’s delegate to only optionally enable the most suitable media file.
	
	NSOpenPanel *panel = [[NSOpenPanel alloc] init];
	panel.allowedFileTypes = AVURLAsset.audiovisualTypes;
	panel.directoryURL = fileURL; // This just works on recent versions of OS X.
	
	[panel beginSheetModalForWindow:_appWindow
				  completionHandler:^(NSInteger result) {
					  if (result == NSFileHandlingPanelOKButton) {
						  NSArray *filesToOpen = panel.URLs;
						  NSError *error = nil;
						  NSURL *sheetFileURL = filesToOpen[0];
						  self.mediaFileBookmark =
						  [sheetFileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
								 includingResourceValuesForKeys:nil
												  relativeToURL:nil
														  error:&error];
						  [self loadAndSetupAssetWithURL:sheetFileURL];
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



- (void)loadAndSetupAssetWithURL:(NSURL *)fileURL
{
	NSImage *icon = [fileURL getResourceValue:&icon
									   forKey:NSURLEffectiveIconKey error:NULL] ? icon : nil;
	
	icon.size = NSMakeSize(32, 32);
	_mTextField.stringValue = fileURL.lastPathComponent;
	_typeImageView.image = icon;
	
	[fileURL startAccessingSecurityScopedResource];
	
#if 0
	if ([[NSFileManager defaultManager] isReadableFileAtPath:fileURL.path]) {
		NSLog(@"FileManager: Yes.");
	}
	if (access([fileURL.path UTF8String], R_OK) != 0) {
		NSLog(@"Sandbox: No.");
	}
#endif

	NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks", @"duration"];
	AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^ (void) {
		dispatch_async(dispatch_get_main_queue(), ^ (void) {
			[self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
			[fileURL stopAccessingSecurityScopedResource];
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
        [self addObserver:self
			   forKeyPath:@"playerLayer.readyForDisplay"
				  options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
				  context:TSCPlayerLayerReadyForDisplay];
    }
    else
    {
        [self stopLoadingAnimationAndHandleError:nil];
        _noVideoImage.hidden = NO;
    }
	
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
	[_playerItem addObserver:self
				  forKeyPath:TSCPlayerItemStatusKeyPath
					 options:0
					 context:TSCPlayerItemReadyToPlay];
	
    [self.player replaceCurrentItemWithPlayerItem:_playerItem];
	
	__weak typeof(self) weakSelf = self;
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
		__strong typeof(self) strongSelf = weakSelf;
		[strongSelf willChangeValueForKey:@"currentTime"];
		[strongSelf didChangeValueForKey:@"currentTime"];
		[strongSelf updateTimestampLineNumber];
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
    else if (context == TSCPlayerItemReadyToPlay)
    {
		if (_playerItem.status == AVPlayerItemStatusReadyToPlay) {
			[self willChangeValueForKey:@"duration"];
			[self didChangeValueForKey:@"duration"];
		}
		
		[_playerItem removeObserver:self forKeyPath:TSCPlayerItemStatusKeyPath];
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

+ (NSSet *)keyPathsForValuesAffectingDuration
{
    return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (CMTime)duration
{
    AVPlayerItem *playerItem = self.player.currentItem;
	if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
		CMTime duration = playerItem.asset.duration;
        return duration;
	}
	else {
        return kCMTimeZero;
	}
}

- (CMTime)currentTime
{
    return [self.player currentTime];
}

- (void)setCurrentTime:(CMTime)time
{
	[self.player seekToTime:time
			toleranceBefore:kCMTimeZero
			 toleranceAfter:kCMTimeZero];
	[self updateTimestampLineNumber];
}

+ (NSSet *)keyPathsForValuesAffectingVolume
{
    return [NSSet setWithObject:@"player.volume"];
}



#pragma mark media-methods

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
	if (self.player.currentItem) {
        CMTime currentTime = [self.player currentTime];
        CMTime timeToAdd   = CMTimeMakeWithSeconds(_replaySlider.intValue, 1);
        CMTime resultTime  = CMTimeSubtract(currentTime,timeToAdd);
        [self.player seekToTime:resultTime];
        [self.player playWithCurrentUserDefaultRate];
        [self updateTimestampLineNumber];
    }
}

- (IBAction)playPauseToggle:(id)sender
{
    if (self.player.rate == 0.f)
    {
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            self.currentTime = kCMTimeZero;
        }
		[self.player playWithCurrentUserDefaultRate];
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
								 intoText:(NSMutableAttributedString * _Nonnull)text
								   string:(NSMutableString * _Nonnull)string
							 prependSpace:(BOOL)prependSpace
							  appendSpace:(BOOL)appendSpace
						   timeStampRange:(NSRange *)timeStampRangePtr
{
	NSInteger stringLength = string.length;
	NSAssert((insertionLocation <= stringLength), @"Invalid insertionLocation."); // Equality to string.length is legal. This signifies an append.
	
	NSRange insertionCursor = NSMakeRange(insertionLocation, 0);
	NSRange insertionRange = insertionCursor;
	
	NSRange timeStampRange = NSMakeRange(NSNotFound, 0);

	NSString *timeString = [JXCMTimeStringTransformer timecodeStringForCMTime:time];
	
	NSString * const space = @" ";
	const NSUInteger spaceLength = 1;

	NSString * const prefix = @"#";
	const NSUInteger prefixLength = 1;
	
	NSString * const suffix = @"#";
	const NSUInteger suffixLength = 1;
	
	if (prependSpace) {
		[string replaceCharactersInRange:insertionCursor withString:space];		insertionCursor.location += spaceLength;
	}
	
	timeStampRange.location = insertionCursor.location;

	[string replaceCharactersInRange:insertionCursor withString:prefix];		insertionCursor.location += prefixLength;
	[string replaceCharactersInRange:insertionCursor withString:timeString];	insertionCursor.location += timeString.length;
	[string replaceCharactersInRange:insertionCursor withString:suffix];		insertionCursor.location += suffixLength;
	
	timeStampRange.length = insertionCursor.location - timeStampRange.location;

	if (appendSpace) {
		[string replaceCharactersInRange:insertionCursor withString:space];		insertionCursor.location += spaceLength;
	}
	
	insertionRange.length = insertionCursor.location - insertionRange.location;
	
	[text addAttributes:self.timeStampAttributes range:timeStampRange];
	
	if (timeStampRangePtr != NULL) {
		*timeStampRangePtr = timeStampRange;
	}
	
	return insertionRange;
}

- (void)createTimeStamp:(id)sender
{
	[self insertTimeStampAfterSelectionAppendingNewline:NO];
}

- (void)createAutomaticTimeStamp:(id)sender
{
	// No need to check [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue].
	[self insertTimeStampAfterSelectionAppendingNewline:YES];
}

- (void)insertTimeStampAfterSelectionAppendingNewline:(BOOL)appendNewline
{
	if (self.player.currentItem) {
		NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
		NSMutableString *string = text.mutableString;
		CMTime time = self.currentTime;
		
		NSUInteger insertionLocation = NSMaxRange(_textView.selectedRange); // Define insertion point as the location at the end of the current selection.
		NSRange insertionRange = NSMakeRange(insertionLocation, 0);
		
		TSCLocalWhitespace hasWhitespace = [_textView.textStorage.string localWhitespaceForLocation:insertionLocation];
		
		NSRange timeStampRange;
		
		NSRange insertedRange =
		[self insertTimeStampStringForCMTime:time
										  at:0
									intoText:text
									  string:string
								prependSpace:!hasWhitespace.prefix
								 appendSpace:!hasWhitespace.suffix
							  timeStampRange:&timeStampRange];
		NSRange insertionCursor = NSMakeRange(NSMaxRange(timeStampRange), 0);
		
		if (appendNewline) {
			NSString * const newline = @"\n";
			const NSUInteger newlineLength = 1;
			
			[string replaceCharactersInRange:insertionCursor withString:newline];
			timeStampRange.length += newlineLength;
		}
		
		[_textView insertText:text replacementRange:insertionRange]; // This also enables undo support.
		
		insertedRange.location = insertionLocation;
		NSUInteger insertedRangeEnd = NSMaxRange(insertedRange);
		_textView.selectedRange = NSMakeRange(insertedRangeEnd, 0);
		
        [self updateTimestampLineNumber];
	}
}

- (void)jumpToTimeStamp:(NSNotification *)note
{
	NSButton *tsButton = note.object;
	NSWindow *tsButtonWindow = tsButton.window;
	
	if (tsButtonWindow == _appWindow) {
		NSString *timestampTimeString = tsButton.cell.representedObject;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		CMTime newTime = [JXCMTimeStringTransformer CMTimeForTimecodeString:timestampTimeString];
		BOOL timestampReplay = [[defaults objectForKey:@"timestampReplay"] boolValue];
		BOOL timestampAutoPlay = [[defaults objectForKey:@"timestampAutoPlay"] boolValue];
		
		if (timestampReplay) {
			CMTime timeToSubstract = CMTimeMakeWithSeconds(_replaySlider.intValue, 1);
			newTime = CMTimeSubtract(newTime, timeToSubstract);
		}
		
		[self.player seekToTime:newTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
		
		if (timestampReplay || timestampAutoPlay) {
			[self.player playWithCurrentUserDefaultRate];
		}
		
		[self updateTimestampLineNumber];
	}
}


#pragma mark SplitView delegate methods

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMax > splitView.frame.size.width - 250)
    {
        proposedMax = splitView.frame.size.width - 250;
    }
    
    return proposedMax;
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
		_movieFileField.stringValue = [self URLCurrentlyPlayingInPlayer:self.player].absoluteString;
	}
}

- (NSURL *)URLCurrentlyPlayingInPlayer:(AVPlayer *)player {
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

- (NSRect)newFrameForNewHUD:(NSPanel *)panel contentView:(NSView *)view
{
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

- (void)openURLInDefaultBrowser:(id)sender
{
	
	NSURL* url = [NSURL URLWithString:@"http://code.google.com/p/transcriptions/"];
	[[NSWorkspace sharedWorkspace] openURLs:@[url]
					withAppBundleIdentifier:NULL
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
}

- (IBAction)reportBug:(id)sender{
	
    NSURL* url = [NSURL URLWithString:@"https://code.google.com/p/transcriptions/issues/list"];
    [[NSWorkspace sharedWorkspace] openURLs:@[url]
                    withAppBundleIdentifier:NULL
                                    options:NSWorkspaceLaunchDefault
             additionalEventParamDescriptor:NULL
                          launchIdentifiers:NULL];
	
}

- (IBAction)writeFeedback:(id)sender{
    
    NSString* mailToString = @"mailto:transcriptionsdev@gmail.com";
    NSURL* emailURL = [NSURL URLWithString:mailToString];
    [[NSWorkspace sharedWorkspace] openURL:emailURL];
    
}

- (IBAction)redirectToDonationPage:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"http://www.unet.univie.ac.at/~a0206600/TranscriptionsDonate.html"];
	[[NSWorkspace sharedWorkspace] openURLs:@[url]
					withAppBundleIdentifier:NULL
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
}


#pragma mark Document Informations Panel METHODS

// TODO: Add better calculations for word and character counts.
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


- (void)showInfoSheet:(NSWindow *)window
{
    [self.windowForSheet beginSheet:_infoPanel completionHandler:^(NSModalResponse returnCode) {
		[_infoPanel orderOut:self];
	}];
}

- (void)closeInfoSheet:(id)sender
{
    [self.windowForSheet endSheet:_infoPanel];
}


- (void)startURLSheet:(id)sender
{
	[self showURLSheet:_appWindow];
}


- (void)showURLSheet:(NSWindow *)window
{
	[self.windowForSheet beginSheet:_URLPanel completionHandler:^(NSModalResponse returnCode) {
		[_URLPanel orderOut:self];
	}];
	// FIXME: Is this still necessary? Looks like a hack. ;)
	_URLPanel.minSize = _URLPanel.frame.size;
	_URLPanel.maxSize = _URLPanel.frame.size;
}

- (void)closeURLSheet:(id)sender
{
	[self.windowForSheet endSheet:_URLPanel];
}


#pragma mark timestamp line numbers

- (void)updateTimestampLineNumber
{
	if (!_playerItem) {
		_textView.highlightLineNumber = 0;
		return;
	}
	
	NSString * const theString = _textView.string;
	const CMTime currentTime = CMTimeAbsoluteValue(self.currentTime);
	const CMTime mediaEndTime = CMTimeAbsoluteValue(self.duration);
	
	const NSRange fullRange = NSMakeRange(0, theString.length);

	// FIXME: Cache timeStampsSorted until invalidated by a change to the text.
	NSMutableArray *timeStamps = [NSMutableArray array];
	TSCTimeStampEnumerationOptions options = TSCTimeStampEnumerationStringNotRequired;
	
	[theString enumerateTimeStampsInRange:fullRange
								  options:options
							   usingBlock:^(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop) {
								   TSCTimeSourceRange *timeStamp =
								   [TSCTimeSourceRange timeSourceRangeWithTime:time
																		 range:timeStampRange];
								   
								   [timeStamps addObject:timeStamp];
							   }];
	
	TSCTimeSourceRange *mediaEndStamp =
	[TSCTimeSourceRange timeSourceRangeWithTime:mediaEndTime
										  range:NSMakeRange(NSNotFound, 0)];
	[timeStamps addObject:mediaEndStamp];
	
	NSMutableArray *timeStampsSorted = [timeStamps mutableCopy];
	[timeStampsSorted sortWithOptions:NSSortStable usingComparator:^(TSCTimeSourceRange *timeStamp1, TSCTimeSourceRange *timeStamp2) {
		CMTime a = timeStamp1.time;
		CMTime b = timeStamp2.time;
		
		int32_t comparisonResult = CMTimeCompare(a, b);
		switch (comparisonResult) {
			case -1:
				return NSOrderedAscending;
				break;
				
			case 1:
				return NSOrderedDescending;
				break;
				
			default:
				return NSOrderedSame;
				break;
		}
	}];
	
	TSCTimeSourceRange *closestTimeStamp = nil;
	
	if (timeStampsSorted.count > 0) {
		TSCTimeSourceRange *firstTimeStamp = timeStampsSorted.firstObject;
		closestTimeStamp = firstTimeStamp;
	}
	
	TSCTimeSourceRange *previousTimeStamp = nil;
	for (TSCTimeSourceRange *thisTimeStamp in timeStampsSorted) {
		if (previousTimeStamp != nil) {
			CMTime previousTime = previousTimeStamp.time;
			CMTime thisTime = thisTimeStamp.time;
			
			if (CMTIME_COMPARE_INLINE(previousTime, <=, currentTime) &&
				CMTIME_COMPARE_INLINE(currentTime, <, thisTime)) {
				closestTimeStamp = previousTimeStamp;
				break;
			}
		}
		
		previousTimeStamp = thisTimeStamp;
	}
	
	if (closestTimeStamp) {
		//CMTime closestTime = closestStamp.time;
		NSRange closestRange = closestTimeStamp.range;
		//NSLog(@"%@", closestStamp);
		
		// FIXME: Rewrite so that we tell the text view which range we want to have the line marked for.
		// It should have a range-to-line mapping already.
		__block NSUInteger lineIndex = 0;
		[theString enumerateSubstringsInRange:fullRange
									  options:(NSStringEnumerationSubstringNotRequired | NSStringEnumerationByLines)
								   usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
									   if (NSLocationInRange(closestRange.location, substringRange)) {
										   *stop = YES;
										   return;
									   }
									   
									   lineIndex++;
								   }];
		
		_textView.highlightLineNumber = lineIndex + 1;
		_textView.needsDisplay = YES;
	}
	else {
		_textView.highlightLineNumber = 0;
	}
}

#pragma mark printing

- (IBAction)printThisDocument:(id)sender
{
	NSTextView *printTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 468, 648)];
	printTextView.editable = NO;
	[printTextView.textStorage setAttributedString:_textView.attributedString];
	
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printTextView];
	[printOperation runOperation];
}

@end



