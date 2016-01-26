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


@implementation TSCTextView {
	NSColor *_highlightColor;
	NSColor *_backgroundColor;
	
	NSColor *_highlightSeparatorColor;
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
	
	_paragraphAttributes = [@{
							  NSFontAttributeName: [NSFont boldSystemFontOfSize:9],
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
	
	point.x -= self.textContainerOrigin.x;
    point.y -= self.textContainerOrigin.y;
	
	NSUInteger glyphIndex =
	[layoutManager glyphIndexForPoint:point
					  inTextContainer:textContainer];
	NSRect glyphRect =
	[layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
							 inTextContainer:textContainer];
	
	NSString * const theString = self.string;
	const NSRange fullRange = NSMakeRange(0, theString.length);
	
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
		
		TSCTimeStampEnumerationOptions options = TSCTimeStampEnumerationTimeNotRequired;
		
		[theString enumerateTimeStampsInRange:lineCharRange
									  options:options
								   usingBlock:^(NSString *timeCode, CMTime time, NSRange timeStampRange, BOOL *stop) {
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
										   
										   timeButtonCell.representedObject = timeCode;

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

- (void)drawRect:(NSRect)aRect
{
	const CGFloat marginWidth = 35.0;
	
	NSSize tcSize = self.textContainer.containerSize;
	tcSize.width = self.frame.size.width;
	
	if (_drawParagraphNumbers) {
		tcSize.width += marginWidth;
	}
	
	self.textContainer.containerSize = tcSize;
	[super drawRect:aRect];
	
	if (!_drawParagraphNumbers) {
		return;
	}
	
	NSColor * const backgroundColor = _backgroundColor;
	NSColor * const highlightColor = _highlightColor;
	
	NSColor * const highlightSeparatorColor = _highlightSeparatorColor;
	
	[backgroundColor set];
	
	NSRect documentVisibleRect = self.enclosingScrollView.documentVisibleRect;
	
	NSRect marginRect = documentVisibleRect;
	marginRect.size.width = marginWidth;
	NSRectFill(marginRect);
	
	CGContextSetShouldAntialias([NSGraphicsContext currentContext].graphicsPort, NO);
	[[NSColor lightGrayColor] set];
	
	NSPoint p1 = NSMakePoint(marginWidth, marginRect.origin.y);
	NSPoint p2 = NSMakePoint(marginWidth, marginRect.origin.y + marginRect.size.height);
	[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
	
	CGContextSetShouldAntialias([NSGraphicsContext currentContext].graphicsPort, YES);
	
	NSLayoutManager *layoutManager = self.layoutManager;
	
	NSString * const theString = self.string;
	const NSRange fullRange = NSMakeRange(0, theString.length);
	
	__block NSUInteger lineIndex = 0;
	[theString enumerateSubstringsInRange:fullRange
								  options:(NSStringEnumerationSubstringNotRequired | NSStringEnumerationByLines)
							   usingBlock:
	 ^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
		 const NSRange lineGlyphRange =
		 [layoutManager glyphRangeForCharacterRange:substringRange
							   actualCharacterRange:NULL];
		 
		 const NSUInteger firstGlyphIndex = lineGlyphRange.location;
		 
		 NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:firstGlyphIndex
														   effectiveRange:NULL];
		 
		 lineRect.size.width = 16.0;
		 
		 if (NSContainsRect(documentVisibleRect, lineRect)) {
			 NSUInteger lineNumber = (lineIndex + 1);
			 const NSUInteger highlightLineNumber = _highlightLineNumber;
			 
			 if (lineNumber == highlightLineNumber) {
				 NSBezierPath *aPath = [NSBezierPath bezierPath];
				 [highlightSeparatorColor set];
				 [aPath moveToPoint:NSMakePoint(1.0, lineRect.origin.y)];
				 [aPath lineToPoint:NSMakePoint(marginWidth, lineRect.origin.y)];
				 aPath.lineCapStyle = NSSquareLineCapStyle;
				 [aPath stroke];
				 
				 NSColor * const endingColor = highlightColor;
				 NSColor * const startingColor = backgroundColor;
				 NSGradient *aGradient =
				 [[NSGradient alloc] initWithStartingColor:startingColor
											   endingColor:endingColor];
				 
				 NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, lineRect.origin.y, 34.6, 30.0)];
				 [aGradient drawInBezierPath:bezierPath angle:270];
			 }
			 
			 NSString *numberString = [NSString stringWithFormat:@"%lu", (unsigned long)lineNumber];
			 NSSize stringSize = [numberString sizeWithAttributes:_paragraphAttributes];
			 // FIXME: Calculate real baseline-aligned rect for this specific text line and draw there.
			 [numberString drawAtPoint:NSMakePoint(32.0 - stringSize.width, lineRect.origin.y + 3)
						withAttributes:_paragraphAttributes];
		 }
		 
		 lineIndex++;
	 }];
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

@end
