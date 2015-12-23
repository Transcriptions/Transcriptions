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


@implementation TSCTextView

- (instancetype)init
{
	self = [super init];
	
	if (self) {
		_paragraphAttributes = [@{
								  NSFontAttributeName: [NSFont boldSystemFontOfSize:9],
								  NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:.50 alpha:1.0],
								  } mutableCopy];
		
		_timeLineNumber = 0;
	}
	
	return self;
}

- (void)awakeFromNib
{
	self.textStorage.delegate = self;
	
	drawParagraphNumbers = YES;
	self.font = [NSFont fontWithName:@"Helvetica" size:13];
	[self refresh];
	[self insertText:@""];
    self.usesFindBar = YES;
    self.enclosingScrollView.contentView.postsBoundsChangedNotifications = YES;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(boundsDidChangeNotification:)
                   name:NSViewBoundsDidChangeNotification
                 object:self.enclosingScrollView.contentView];
	self.window.acceptsMouseMovedEvents = YES;
	
}

- (void)mouseMoved:(NSEvent *)theEvent 
{
    NSLayoutManager *layoutManager = self.layoutManager;
    NSTextContainer *textContainer = self.textContainer;
    NSUInteger glyphIndex, textLength = self.textStorage.length;
    NSPoint point = [self convertPoint:theEvent.locationInWindow
							  fromView:nil];
    NSRect glyphRect;
    
	point.x -= self.textContainerOrigin.x;
    point.y -= self.textContainerOrigin.y;
	glyphIndex = [layoutManager glyphIndexForPoint:point
								   inTextContainer:textContainer];
	glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
										 inTextContainer:textContainer];
    if (NSPointInRect(point, glyphRect)) {
		NSUInteger characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
		
		NSRange lineGlyphRange = NSMakeRange(0, textLength);
		[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
										effectiveRange:&lineGlyphRange];
        NSRange lineCharRange =
		[layoutManager characterRangeForGlyphRange:lineGlyphRange
								  actualGlyphRange:NULL];
		
		NSString *theString = self.string;
		
		NSMutableArray *timeButtonArray = [[NSMutableArray alloc] init];

		[theString enumerateTimeStampsInRange:lineCharRange
								   usingBlock:^(NSString *timeCode, NSRange timeStampRange, BOOL *stop) {
									   if ((timeStampRange.length > 0) &&
										   (NSLocationInRange(characterIndex, timeStampRange))) {
										   NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:timeStampRange
																					  actualCharacterRange:NULL];
										   NSRect wordRect = [layoutManager boundingRectForGlyphRange:glyphRange
																					  inTextContainer:textContainer];
										   NSRect buttonRect = NSMakeRect(wordRect.origin.x - 1,
																		  wordRect.origin.y,
																		  wordRect.size.width + 2,
																		  wordRect.size.height + 2);
										   
										   NSButton *timeButton = [[NSButton alloc] initWithFrame:buttonRect];
										   timeButton.enabled = NO;
										   
										   NSButtonCell *timeButtonCell = [[NSButtonCell alloc] init];
										   //only used in borderless buttons:
										   timeButtonCell.backgroundColor = [NSColor magentaColor];
										   ///
										   timeButtonCell.bezelStyle = NSRoundRectBezelStyle;
										   //timeButtonCell.title = timeCode;
										   timeButtonCell.title = @"";
										   timeButtonCell.gradientType = NSGradientConcaveWeak;
										   timeButtonCell.transparent = NO;
										   timeButtonCell.representedObject = timeCode;

										   timeButton.cell = timeButtonCell;
										   timeButton.action = @selector(timeStampPressed:);
										   
										   [timeButtonArray addObject:timeButton];
									   }
								   }];
		
		self.subviews = timeButtonArray;
	}
	else {
		self.subviews = @[];
		[self setNeedsDisplay:YES];
	}
}

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
		
		for (id anObject in insertions.arrangedObjects) {
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
        if (!drawParagraphNumbers) {
            NSSize tcSize = self.textContainer.containerSize;
            tcSize.width = self.frame.size.width;
            self.textContainer.containerSize = tcSize;
            [super drawRect:aRect];
            return;
        }
        NSSize tcSize = self.textContainer.containerSize;
        tcSize.width = self.frame.size.width+35.0;
        self.textContainer.containerSize = tcSize;
        [super drawRect:aRect];
        [[NSColor colorWithDeviceWhite:0.95 alpha:1.0] set];
        NSRect documentVisibleRect = self.enclosingScrollView.documentVisibleRect;
        documentVisibleRect.origin.y -= 35.0;
        documentVisibleRect.size.height += 65.0;
        NSRect marginRect = documentVisibleRect;
        marginRect.size.width = 35.0;
        NSRectFill(marginRect);
        CGContextSetShouldAntialias([NSGraphicsContext currentContext].graphicsPort, NO);
        [[NSColor lightGrayColor] set];
        NSPoint p1 = NSMakePoint(35.0,marginRect.origin.y);
        NSPoint p2 = NSMakePoint(35.0,marginRect.origin.y+marginRect.size.height);
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
        CGContextSetShouldAntialias([NSGraphicsContext currentContext].graphicsPort, YES);
        NSRange lineRange;
        NSRect lineRect;
        NSArray* lines = [self.string componentsSeparatedByString:@"\n"];
        NSLayoutManager* layoutManager = self.layoutManager;
        int i;
        int pos = 0;
        int emptyString = 0;
        NSString* s;
        NSSize stringSize;
        for (i=0;i<lines.count;i++) {
            if (pos <self.string.length) {
                lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:pos effectiveRange:&lineRange];
                pos += [lines[i] length]+1;
                lineRect.size.width = 16.0;
                if ([lines[i] length] > 0){
                    if (NSContainsRect(documentVisibleRect,lineRect)) {
                        int insertNumber = (i + 1) - emptyString;
                        int timeLine = self.timeLineNumber;
                        if (insertNumber == timeLine) {
                            NSBezierPath* aPath = [NSBezierPath bezierPath];
                            [[NSColor colorWithCalibratedRed:0.37 green:0.42 blue:0.49 alpha:1.0] set];
                            [aPath moveToPoint:NSMakePoint(1.0, lineRect.origin.y)];
                            [aPath lineToPoint:NSMakePoint(35.0, lineRect.origin.y)];
                            aPath.lineCapStyle = NSSquareLineCapStyle;
                            [aPath stroke];
                            NSColor *startingColor;
                            NSColor *endingColor;
                            NSGradient* aGradient;
                            endingColor = [NSColor yellowColor];
                            startingColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
                            aGradient = [[NSGradient alloc]
                                         initWithStartingColor:startingColor
                                         endingColor:endingColor];
                            
                            NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, lineRect.origin.y, 34.6, 30.0)];
                            [aGradient drawInBezierPath:bezierPath angle:270];
                        }
                        s = [NSString stringWithFormat:@"%i", insertNumber];
                        stringSize = [s sizeWithAttributes:nil];
                        [s drawAtPoint:NSMakePoint(32.0-stringSize.width,lineRect.origin.y+1) withAttributes:_paragraphAttributes];
                    }
                }
                else{
                    emptyString += 1;
                }
            }
        }
}

- (void)boundsDidChangeNotification:(NSNotification *)notification
{
    [self setNeedsDisplay: YES];
}

- (void)refresh
{
	if (drawParagraphNumbers) {
		self.textContainer.lineFragmentPadding = 38.0;
		[self.textContainer setWidthTracksTextView:NO];
	}
	else {
		self.textContainer.lineFragmentPadding = 2.0;
		[self.textContainer setWidthTracksTextView:YES];
	}

	[self setNeedsDisplay:YES];
}

- (void)showParagraphs:(id)sender
{
	drawParagraphNumbers = (BOOL)[sender state];
	[self refresh];
}


- (void)timeStampPressed:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"aTimestampPressed" object:sender];
}

@end
