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

/*
Thanks to Einar Andersson for LineNumbering Code!
Original code can be found here:http://roventskij.net/index.php?p=3
*/ 

#import "TSCTextView.h"

#import "NSString+TSCTimeStamp.h"
#import "NSString+TSCWhitespace.h"


NSString * const	TSCLineNumberAttributeName		= @"TSCLineNumberAttributeName";
NSString * const	TSCTimeStampAttributeName		= @"TSCTimeStampAttributeName";

NSString * const	TSCTimeStampChangedNotification = @"TSCTimeStampChangedNotification";


typedef struct _TSCUpdateFlags {
	BOOL lineNumberUpdate;
	BOOL timeStampUpdate;
} TSCUpdateFlags;


@implementation TSCTextView {
	NSColor *_highlightColor;
	NSColor *_backgroundColor;
	
	NSColor *_highlightSeparatorColor;
	
	TSCUpdateFlags _willNeed;
}

- (instancetype)initWithFrame:(NSRect)frameRect
				textContainer:(NSTextContainer *)container
{
	self = [super initWithFrame:frameRect
				  textContainer:container];
	
	if (self) {
	}
	
	return self;
}

- (void)awakeFromNib
{
	self.textStorage.delegate = self;
	
	_paragraphNumberAttributes = [@{
									NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:9 weight:NSFontWeightRegular],
									NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:.50 alpha:1.0],
									} mutableCopy];
	
	_highlightLineNumber = 0;
	
	_highlightColor = [NSColor yellowColor];
	_backgroundColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
	
	_highlightSeparatorColor = [NSColor colorWithCalibratedRed:0.37 green:0.42 blue:0.49 alpha:1.0];
	
	_drawParagraphNumbers = YES;
	
	self.font = [NSFont fontWithName:@"Helvetica" size:13];
	
    self.usesFindBar = YES;
    self.enclosingScrollView.contentView.postsBoundsChangedNotifications = YES;
	
	self.window.acceptsMouseMovedEvents = YES;
	
	[self refresh];
	[self insertText:@"" replacementRange:NSMakeRange(0, 0)];
	
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(boundsDidChangeNotification:)
                   name:NSViewBoundsDidChangeNotification
                 object:self.enclosingScrollView.contentView];
}

- (void)mouseMoved:(NSEvent *)theEvent 
{
    NSLayoutManager *layoutManager = self.layoutManager;
    NSTextContainer *textContainer = self.textContainer;
	
    NSPoint point = [self convertPoint:theEvent.locationInWindow
							  fromView:nil];
	
	NSPoint textContainerOrigin = self.textContainerOrigin;
	point.x -= textContainerOrigin.x;
    point.y -= textContainerOrigin.y;
	
	NSUInteger glyphIndex =
	[layoutManager glyphIndexForPoint:point
					  inTextContainer:textContainer];
	NSRect glyphRect =
	[layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
							 inTextContainer:textContainer];
	
	NSTextStorage * const textStorage = self.textStorage;
	const NSRange fullRange = NSMakeRange(0, textStorage.length);
	
	NSDictionary *markAttributes = @{
	  NSForegroundColorAttributeName: [NSColor blackColor],
	  };
	
	// Remove previous temporary attributes.
	for (NSString *attributeKey in markAttributes.allKeys) {
		[layoutManager removeTemporaryAttribute:attributeKey
							  forCharacterRange:fullRange];
	}
	
    if (NSPointInRect(point, glyphRect)) {
		NSUInteger characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
		
		NSRange lineGlyphRange;
		(void)[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
											  effectiveRange:&lineGlyphRange];
        NSRange lineCharRange =
		[layoutManager characterRangeForGlyphRange:lineGlyphRange
								  actualGlyphRange:NULL];
		
		NSMutableArray *timeButtonArray = [[NSMutableArray alloc] init];
		
		NSAttributedStringEnumerationOptions timeStampSearchOptions = 0;
		
		[textStorage enumerateAttribute:TSCTimeStampAttributeName
								inRange:lineCharRange
								options:timeStampSearchOptions
							 usingBlock:
		 ^(NSValue * _Nullable timeStampValue, NSRange timeStampRange, BOOL * _Nonnull stop) {
			 if (!timeStampValue)  return;
			 
			 if ((NSLocationInRange(characterIndex, timeStampRange))) {
				 
				 [layoutManager addTemporaryAttributes:markAttributes
									 forCharacterRange:timeStampRange];
				 
				 NSRange timeStampGlyphRange =
				 [layoutManager glyphRangeForCharacterRange:timeStampRange
									   actualCharacterRange:NULL];
				 
				 NSRect timeStampRect =
				 [layoutManager boundingRectForGlyphRange:timeStampGlyphRange
										  inTextContainer:textContainer];
				 
				 NSRect buttonRect = NSMakeRect(timeStampRect.origin.x - 1,
												timeStampRect.origin.y,
												timeStampRect.size.width + 2,
												timeStampRect.size.height + 2);
				 
				 NSButtonCell *timeButtonCell = [[NSButtonCell alloc] init];
				 timeButtonCell.bezelStyle = NSRoundRectBezelStyle;
				 timeButtonCell.title = @"";
				 
				 timeButtonCell.representedObject = timeStampValue;
				 
				 NSButton *timeButton = [[NSButton alloc] initWithFrame:buttonRect];
				 timeButton.cell = timeButtonCell;
				 timeButton.target = nil; // Explicitly setting this to first responder.
				 timeButton.action = @selector(timeStampPressed:);
				 
				 [timeButtonArray addObject:timeButton];
			 }
		 }];
		
		self.subviews = timeButtonArray;
	}
	else {
		self.subviews = @[];
	}
}

// This is called for every key-press.
// The ivars accumulate previous key sequences that trigger special behavior.
- (void)keyDown:(NSEvent *)theEvent
{
	NSString *eventCharacters = theEvent.characters;
	
	if ([eventCharacters isEqualToString:@"@"]) {
		_atCharacterKey = YES;
	}
	
	if ([eventCharacters isEqualToString:@" "]) {
		_spaceCharacterCheck = YES;
		_enterCharacterCheck = NO;
	}
	else if ([eventCharacters isEqualToString:@"\r"]) {
		_spaceCharacterCheck = NO;
		_enterCharacterCheck = YES;
	}
	else {
		_spaceCharacterCheck = NO;
		_enterCharacterCheck = NO;
	}
	
	if (_atCharacterKey &&
		(_spaceCharacterCheck || _enterCharacterCheck)) {
		NSString *textString = self.textStorage.string;
		
		for (id anObject in _insertions.arrangedObjects) {
			NSString *searchString = [NSString stringWithFormat:@"@%@", anObject[@"substString"]];
			NSAttributedString *replacement = anObject[@"insertString"];
			NSString *replacementString = replacement.string;
			if ([textString rangeOfString:searchString].location != NSNotFound) {
				[self.textStorage.mutableString replaceOccurrencesOfString:searchString
																withString:replacementString
																   options:0 // Allow for representational Unicode differences.
																	 range:NSMakeRange(0, self.textStorage.length)];
				[self setNeedsDisplayInRect:self.enclosingScrollView.contentView.visibleRect];
				_atCharacterKey = NO;
			}
		}
	}
	
	BOOL autoTimestamp = [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue];
	
	if (_enterCharacterCheck && autoTimestamp) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"automaticTimestamp"
															object:self];
	}
	
	[self interpretKeyEvents:@[theEvent]];
}

const CGFloat numbersBarWidth = 35.0;
const CGFloat numberStringRightMargin = 3.0;

- (void)drawLineNumber:(NSUInteger)lineNumber
		   forLineRect:(NSRect)lineRect
		  ifWithinRect:(NSRect)documentVisibleRect
{
	if (NSIntersectsRect(documentVisibleRect, lineRect)) {
		const NSUInteger highlightLineNumber = _highlightLineNumber;
		
		if (lineNumber == highlightLineNumber) {
			NSColor * const highlightColor = _highlightColor;
			NSColor * const highlightSeparatorColor = _highlightSeparatorColor;
			
			NSBezierPath *aPath = [NSBezierPath bezierPath];
			[highlightSeparatorColor set];
			[aPath moveToPoint:NSMakePoint(1.0, lineRect.origin.y)];
			[aPath lineToPoint:NSMakePoint(numbersBarWidth, lineRect.origin.y)];
			aPath.lineCapStyle = NSSquareLineCapStyle;
			[aPath stroke];
			
			NSColor * const endingColor = highlightColor;
			NSColor * const startingColor = _backgroundColor;
			NSGradient *aGradient =
			[[NSGradient alloc] initWithStartingColor:startingColor
										  endingColor:endingColor];
			
			NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, lineRect.origin.y, 34.6, 30.0)];
			[aGradient drawInBezierPath:bezierPath angle:270];
		}
		
		NSString *numberString = [NSString stringWithFormat:@"%lu", (unsigned long)lineNumber];
		NSSize stringSize = [numberString sizeWithAttributes:_paragraphNumberAttributes];
		
		// Draw the line number aligned right (with numberStringRightMargin) within the numbers bar
		// and centered vertically relative to the line.
		NSRect rect =
		NSMakeRect(numbersBarWidth - numberStringRightMargin - stringSize.width,
				   lineRect.origin.y + (NSHeight(lineRect) - stringSize.height) / 2.0,
				   MIN(stringSize.width, numbersBarWidth),
				   NSHeight(lineRect));
		
		[numberString drawInRect:rect
				  withAttributes:_paragraphNumberAttributes];
	}
}

- (void)drawRect:(NSRect)aRect
{
	NSSize tcSize = self.textContainer.containerSize;
	tcSize.width = self.frame.size.width;
	
	if (_drawParagraphNumbers) {
		tcSize.width += numbersBarWidth;
	}
	
	self.textContainer.containerSize = tcSize;
	[super drawRect:aRect];
	
	if (!_drawParagraphNumbers) {
		return;
	}
	
	NSColor * const backgroundColor = _backgroundColor;
	[backgroundColor set];
	
	NSRect documentVisibleRect = self.enclosingScrollView.documentVisibleRect;
	
	NSRect numbersBarRect = documentVisibleRect;
	numbersBarRect.size.width = numbersBarWidth;
	NSRectFill(numbersBarRect);
	
	CGContextRef const context = [NSGraphicsContext currentContext].graphicsPort;
	
	CGContextSetShouldAntialias(context, NO);
	
	[[NSColor lightGrayColor] set];
	
	NSPoint p1 = NSMakePoint(numbersBarWidth, numbersBarRect.origin.y);
	NSPoint p2 = NSMakePoint(numbersBarWidth, numbersBarRect.origin.y + numbersBarRect.size.height);
	[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
	
	CGContextSetShouldAntialias(context, YES);
	
	NSLayoutManager *layoutManager = self.layoutManager;
	
	NSTextStorage *textStorage = self.textStorage;
	const NSRange visibleTextRange = self.visibleTextRange;
	
	__block NSUInteger previousLineNumber = NSNotFound;

	[textStorage enumerateAttribute:TSCLineNumberAttributeName
							inRange:visibleTextRange
							options:0
						 usingBlock:
	 ^(NSNumber * _Nullable lineNum, NSRange attributeRange, BOOL * _Nonnull stop) {
		 if (!lineNum)  return;
		 
		 NSUInteger lineNumber = lineNum.unsignedIntegerValue;
		 //NSLog(@"%tu", lineNumber);
		 
		 const NSRange lineGlyphRange =
		 [layoutManager glyphRangeForCharacterRange:attributeRange
							   actualCharacterRange:NULL];
		 
		 const NSUInteger firstGlyphIndex = lineGlyphRange.location;
		 
		 NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:firstGlyphIndex
														   effectiveRange:NULL];
		 
		 [self drawLineNumber:lineNumber
				  forLineRect:lineRect
				 ifWithinRect:documentVisibleRect];
		 
		 previousLineNumber = lineNumber;
	 }];
	
	NSRect extraLineFragmentRect = layoutManager.extraLineFragmentRect;
	if ((previousLineNumber != NSNotFound) &&
		!NSEqualRects(extraLineFragmentRect, NSZeroRect)) {
		// The last line is empty, but needs a line number.
		[self drawLineNumber:(previousLineNumber + 1)
				 forLineRect:extraLineFragmentRect
				ifWithinRect:documentVisibleRect];
	}
}

- (NSRange)visibleTextRange
{
	NSScrollView *scrollView = self.enclosingScrollView;
	if (!scrollView) {
		return NSMakeRange(0, 0);
	}
	
	NSLayoutManager *layoutManager = self.layoutManager;
	NSRect visibleRect = self.visibleRect;
	
	NSPoint textContainerOrigin = self.textContainerOrigin;
	visibleRect.origin.x -= textContainerOrigin.x;
	visibleRect.origin.y -= textContainerOrigin.y;
	
	NSTextContainer *textContainer = self.textContainer;

	NSRange glyphRange =
	[layoutManager glyphRangeForBoundingRect:visibleRect
							 inTextContainer:textContainer];
	NSRange characterRange =
	[layoutManager characterRangeForGlyphRange:glyphRange
							  actualGlyphRange:NULL];
	return characterRange;
}

- (void)boundsDidChangeNotification:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (void)refresh
{
	if (_drawParagraphNumbers) {
		self.textContainer.lineFragmentPadding = 38.0;
		[self.textContainer setWidthTracksTextView:NO];
	}
	else {
		self.textContainer.lineFragmentPadding = 2.0;
		[self.textContainer setWidthTracksTextView:YES];
	}

	[self setNeedsDisplay:YES];
}

- (void)showParagraphNumbers:(id)sender
{
	_drawParagraphNumbers = (BOOL)[sender state];
	[self refresh];
}


- (void)timeStampPressed:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"aTimestampPressed" object:sender];
}


TSCUpdateFlags determineUpdateFlagsForTextAndRange(NSTextStorage *textStorage, NSRange editedRange) {
	TSCUpdateFlags flags = (TSCUpdateFlags){NO};
	
	if (editedRange.length == 0) {
		return flags;
	}
	
	NSString * const string = textStorage.string;
	const NSUInteger stringLength = string.length;
	
	if (stringLength == 0) {
		return flags;
	}
	
	flags.lineNumberUpdate = (NSMaxRange(editedRange) == stringLength ||
							  [string containsLineBreak:editedRange]);
	flags.timeStampUpdate = ([string containsTimeStampDelimiter:editedRange] ||
								rangeInTextStorageTouchesTimeStamp(textStorage, editedRange));
	
	return flags;
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange
			  replacementString:(NSString *)replacementString
{
	BOOL shouldChangeText = [super shouldChangeTextInRange:affectedCharRange
										 replacementString:replacementString];
	
	if (shouldChangeText) {
		// Determine required updates due to deletions.
		_willNeed = determineUpdateFlagsForTextAndRange(self.textStorage, affectedCharRange);
	}
	
	return shouldChangeText;
}

#if 0
- (void)textStorage:(NSTextStorage *)textStorage
 willProcessEditing:(NSTextStorageEditActions)editedMask
			  range:(NSRange)editedRange
	 changeInLength:(NSInteger)delta;
{
	// We are not using this delegate method, because we require the latest state of the text.
}
#endif

void mergeUpdateFlagsIntoFirst(TSCUpdateFlags *updateFlags1, TSCUpdateFlags updateFlags2)
{
	updateFlags1->lineNumberUpdate = (updateFlags1->lineNumberUpdate || updateFlags2.lineNumberUpdate);
	updateFlags1->timeStampUpdate = (updateFlags1->timeStampUpdate || updateFlags2.timeStampUpdate);
}

- (void)textStorage:(NSTextStorage *)textStorage
  didProcessEditing:(NSTextStorageEditActions)editedMask
			  range:(NSRange)editedRange
	 changeInLength:(NSInteger)delta;
{
	if (!(editedMask & NSTextStorageEditedCharacters)) {
		// We only need to process the text,
		// if there are actual changes to the characters.
		return;
	}
	
	{
#if 0
		const NSRange fullRange = NSMakeRange(0, textStorage.length);
		NSLog(@"%p, edited: %@, delta: %zd, full: %@", textStorage, NSStringFromRange(editedRange), delta, NSStringFromRange(fullRange));
#endif
		
		// We check, if the editedRange contains at least one line break.
		// Such cases, like adding characters to the current line’s range
		// are already handled, because the range an attribute is attached to
		// in an attributed string grows automatically.
		TSCUpdateFlags needs = determineUpdateFlagsForTextAndRange(textStorage, editedRange);
		mergeUpdateFlagsIntoFirst(&needs, _willNeed);
		
		if (needs.lineNumberUpdate || needs.timeStampUpdate) {
			[textStorage beginEditing];
			
			const TSCAffectedTextRanges ranges =
			affectedTextRangesForTextStorageWithEditedRange(textStorage, editedRange);
			
			if (needs.lineNumberUpdate) {
				updateLineNumbersForTextStorageWithAffectedRanges(textStorage, ranges);
			}
			
			if (needs.timeStampUpdate) {
				updateTimeStampsForTextStorageWithAffectedRanges(textStorage, ranges.linesRange);
			}
			
			[textStorage endEditing];
		}
		
		// FIXME: Currently this needs to be called on every edit,
		// because the ranges in the text may have changed.
		// Find a better way.
		[[NSNotificationCenter defaultCenter] postNotificationName:TSCTimeStampChangedNotification
															object:self];
	}
}

typedef struct _TSCAffectedTextRanges {
	//NSRange editedRange;
	NSRange linesRange;
	NSRange unaffectedRange;
	NSRange affectedRange;
} TSCAffectedTextRanges;

TSCAffectedTextRanges affectedTextRangesForTextStorageWithEditedRange(NSTextStorage *textStorage, NSRange editedRange) {
	NSString * const string = textStorage.string;
	const NSUInteger stringLength = string.length;
	
	if (editedRange.location == NSNotFound) {
		const TSCAffectedTextRanges ranges = {
			//.editedRange = editedRange,
			.linesRange = NSMakeRange(0, stringLength),
			.unaffectedRange = NSMakeRange(0, 0),
			.affectedRange = NSMakeRange(0, stringLength),
		};
		
		return ranges;
	}
	
	const NSRange linesRange = [string lineRangeForRange:editedRange];
	const NSUInteger affectedRangeStart = linesRange.location;
	
	const NSRange unaffectedRange = NSMakeRange(0, affectedRangeStart);
	const NSRange affectedRange = NSMakeRange(affectedRangeStart, stringLength - affectedRangeStart);
	
	const TSCAffectedTextRanges ranges = {
		//.editedRange = editedRange,
		.linesRange = linesRange,
		.unaffectedRange = unaffectedRange,
		.affectedRange = affectedRange,
	};
	
	return ranges;
}

void updateLineNumbersForTextStorageWithAffectedRanges(NSTextStorage *textStorage, const TSCAffectedTextRanges ranges) {
	if (ranges.affectedRange.length == 0) {
		return;
	}
	
	[textStorage removeAttribute:TSCLineNumberAttributeName
						   range:ranges.affectedRange];
	
	__block NSUInteger initialLineNumber = TSCLineNumberNone;
	
	if (ranges.unaffectedRange.length > 0) {
		// Find the previous line number.
		NSAttributedStringEnumerationOptions previousLineNumberSearchOptions =
		(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired |
		 NSAttributedStringEnumerationReverse);
		
		[textStorage enumerateAttribute:TSCLineNumberAttributeName
								inRange:ranges.unaffectedRange
								options:previousLineNumberSearchOptions
							 usingBlock:
		 ^(NSNumber * _Nullable lineNum, NSRange attributeRange, BOOL * _Nonnull stop) {
			 if (!lineNum)  return;
			 
			 initialLineNumber = lineNum.unsignedIntegerValue;
			 *stop = YES;
			 return;
		 }];
	}
	
	NSString * const string = textStorage.string;
	
	__block NSUInteger lineNumber = initialLineNumber + 1;
	__block NSUInteger enumerationEndIndex = 0;
	[string enumerateSubstringsInRange:ranges.affectedRange
							   options:(NSStringEnumerationSubstringNotRequired | NSStringEnumerationByLines)
							usingBlock:
	 ^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
		 [textStorage addAttribute:TSCLineNumberAttributeName
							 value:@(lineNumber)
							 range:enclosingRange];
		 
		 enumerationEndIndex = NSMaxRange(enclosingRange);
		 
		 lineNumber++;
	 }];
	
	const NSUInteger textLength = textStorage.length;
	if (enumerationEndIndex < textLength) {
		const NSRange lastLineRange = NSMakeRange(enumerationEndIndex, textLength - enumerationEndIndex);
		
		[textStorage addAttribute:TSCLineNumberAttributeName
							value:@(lineNumber)
							range:lastLineRange];
	}
}

BOOL rangeInTextStorageTouchesTimeStamp(NSTextStorage *textStorage, NSRange range) {
	__block BOOL foundTimeStamp = NO;
	
	NSAttributedStringEnumerationOptions timeStampSearchOptions =
	(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired);
	
	[textStorage enumerateAttribute:TSCTimeStampAttributeName
							inRange:range
							options:timeStampSearchOptions
						 usingBlock:
	 ^(NSValue * _Nullable timeStampValue, NSRange timeStampRange, BOOL * _Nonnull stop) {
		 if (!timeStampValue)  return;
		 
		 foundTimeStamp = YES;
		 *stop = YES;
		 return;
	 }];
	
	return foundTimeStamp;
}

void updateTimeStampsForTextStorageWithAffectedRanges(NSTextStorage *textStorage, const NSRange linesRange) {
	[textStorage removeAttribute:TSCTimeStampAttributeName
						   range:linesRange];
	
	NSString * const string = textStorage.string;
	
	TSCTimeStampEnumerationOptions options = TSCTimeStampEnumerationStringNotRequired;
	
	[string enumerateTimeStampsInRange:linesRange
							   options:options
							usingBlock:
	 ^(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop) {
		 [textStorage addAttribute:TSCTimeStampAttributeName
							 value:[NSValue valueWithCMTime:time]
							 range:timeStampRange];
	 }];
}

- (void)setHighlightLineNumberForRange:(NSRange)range;
{
	// TODO: Rewrite using some kind of segmenting search similar to binary search.
	// In this case make sure, that we select the first match.
	
	NSTextStorage *textStorage = self.textStorage;
	const NSRange fullRange = NSMakeRange(0, textStorage.length);
	
	__block NSUInteger lineNumber = TSCLineNumberNone;
	
	[textStorage enumerateAttribute:TSCLineNumberAttributeName
							inRange:fullRange
							options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
						 usingBlock:
	 ^(NSNumber * _Nullable lineNum, NSRange attributeRange, BOOL * _Nonnull stop) {
		 if (!lineNum)  return;
		 
		 if (NSLocationInRange(range.location, attributeRange)) {
			 lineNumber = lineNum.unsignedIntegerValue;
			 *stop = YES;
			 return;
		 }
	 }];
	
	_highlightLineNumber = lineNumber;
	self.needsDisplay = YES;
}

@end
