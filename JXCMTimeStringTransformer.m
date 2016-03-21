//
//  JXCMTimeStringTransformer.m
//  Transcriptions
//
//  Created by Jan on 19.12.15.
//
//

#import "JXCMTimeStringTransformer.h"

#import <AVFoundation/AVFoundation.h>

#import "JXTimeCodeParserCore.h"


#define USE_MILLISECONDS	0

const CMTimeScale FractionalSecondTimescale =
#if USE_MILLISECONDS
	1000;
#else
	100;
#endif


@implementation JXCMTimeStringTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

NSString * timecodeStringForCMTime(CMTime time, const CMTimeScale targetTimescale) {
	
	CMTimeScale timescale = time.timescale;
	if (timescale != targetTimescale) {
		time = CMTimeConvertScale(time, targetTimescale, kCMTimeRoundingMethod_Default);
	}
	
	CMTimeValue total_fractional_seconds = time.value;
	CMTimeValue fractional_seconds = total_fractional_seconds % targetTimescale;
	CMTimeValue total_seconds = (total_fractional_seconds - fractional_seconds) / targetTimescale;
	CMTimeValue seconds = total_seconds % 60;
	CMTimeValue total_minutes = (total_seconds - seconds) / 60;
	CMTimeValue minutes = total_minutes % 60;
	CMTimeValue hours = (total_minutes - minutes) / 60;
	
	NSString * const timecodeFormatString =
#if USE_MILLISECONDS
	@"%02d:%02d:%02d.%03d";
#else
	@"%02d:%02d:%02d.%02d";
#endif
	return [NSString stringWithFormat:timecodeFormatString,
			(int)hours,
			(int)minutes,
			(int)seconds,
			(int)fractional_seconds];
}

+ (NSString *)timecodeStringForCMTime:(CMTime)time;
{
	return timecodeStringForCMTime(time, FractionalSecondTimescale);
}

- (id)transformedValue:(id)value
{
	if (!value)  return nil;
	
	CMTime time = [value CMTimeValue];
	
	NSString *timecode = timecodeStringForCMTime(time, FractionalSecondTimescale);
	return timecode;
}


+ (CMTime)CMTimeForTimecodeString:(NSString *)timecodeString;
{
	NSUInteger stringLength = timecodeString.length;
	
	if (stringLength == 0)  return kCMTimeInvalid;
	
	CFStringRef string = (__bridge CFStringRef)(timecodeString);
	
	const CFRange subRange = CFRangeMake(0, stringLength);
	
	CFStringInlineBuffer stringInlineBuffer;
	CFStringInitInlineBuffer(string, &stringInlineBuffer, subRange);
	
	const JXTimeCodeParserState parserStateDefault = {
		.position = Hours,
		.separator = ':',
		.fractionalSeparator = '.',
	};
	JXTimeCodeParserState parser = parserStateDefault;
	
	NSUInteger i; // Index relative to subRange.
	
	for (i = 0;
		 i < subRange.length;
		 i++) {
		const unichar codeUnit = CFStringGetCharacterFromInlineBuffer(&stringInlineBuffer, i);
		
		parseCodeUnitWithState(codeUnit, &parser);
	}
	
	CMTime time;
	if (!parser.error) {
		time = convertComponentsToCMTime(parser.components);
	}
	else {
		time = kCMTimeInvalid;
	}
	
	return time;
}

- (id)reverseTransformedValue:(NSString *)string
{
	if (!string)  return nil;
	
	CMTime time = [self.class CMTimeForTimecodeString:string];
	
	NSValue *value = [NSValue valueWithCMTime:time];
	return value;
}

@end

/*
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

