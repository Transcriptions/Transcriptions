//
//  JXTimeCodeParserCore.h
//  Transcriptions
//
//  Created by Jan on 19.01.16.
//
//

#pragma once


// Static hinting for the compiler. Mark the likely/unlikely code path for a conditional.
#if defined(__GNUC__) && __GNUC__ >= 4
#	define LIKELY(expr)    (__builtin_expect((bool)(expr), 1))
#	define UNLIKELY(expr)  (__builtin_expect((bool)(expr), 0))
#else
#	define LIKELY(expr)    (expr)
#	define UNLIKELY(expr)  (expr)
#endif


typedef struct {
	uint32_t hours;
	uint32_t minutes;
	uint32_t seconds;
	uint32_t fractional;
	uint32_t fractionalDigits;
} JXTimeCodeComponents;

typedef enum {
	Undefined = 0,
	Hours,
	Minutes,
	Seconds,
	Fractional,
} JXTimeCodeParserPosition;

typedef struct {
	JXTimeCodeComponents components;
	JXTimeCodeParserPosition position;
	unichar separator;
	unichar fractionalSeparator;
	BOOL error;
	
#if DEBUG
	uint32_t digitCount;
#endif
} JXTimeCodeParserState;


NS_INLINE BOOL ASCIIUnicharIsDigit(unichar c) {
	return ('0' <= c && c <= '9');
}

NS_INLINE BOOL addDigitToValue(unichar codeUnit, uint32_t *value) {
	if (ASCIIUnicharIsDigit(codeUnit)) {
		if (*value > 0) {
			*value *= 10;
		}
		*value += codeUnit - '0';
		
		return YES;
	}
	else {
		return NO;
	}
	
}

NS_INLINE void parseNonFractionalCodeUnit(unichar codeUnit, uint32_t *valuePtr, JXTimeCodeParserState *parser, const unichar separator) {
	if (addDigitToValue(codeUnit, valuePtr)) {
#if DEBUG
		parser->digitCount += 1;
#endif
	}
	else if (codeUnit == separator) {
#if DEBUG
		parser->digitCount = 0;
#endif
		// Transition to expecting and parsing next position.
		parser->position += 1;
	}
	else {
		parser->error = YES;
	}
}

NS_INLINE void parseCodeUnitWithState(unichar codeUnit, JXTimeCodeParserState *parser) {
	uint32_t *valuePtr;
	
	switch (parser->position) {
		case Hours:
			valuePtr = &(parser->components.hours);
			parseNonFractionalCodeUnit(codeUnit, valuePtr, parser, parser->separator);
			break;
			
		case Minutes:
			valuePtr = &(parser->components.minutes);
			parseNonFractionalCodeUnit(codeUnit, valuePtr, parser, parser->separator);
			break;
			
		case Seconds:
			valuePtr = &(parser->components.seconds);
			parseNonFractionalCodeUnit(codeUnit, valuePtr, parser, parser->fractionalSeparator);
			break;
			
		case Fractional:
			valuePtr = &(parser->components.fractional);
			
			if (addDigitToValue(codeUnit, valuePtr)) {
				parser->components.fractionalDigits += 1;
			}
			else {
				parser->error = YES;
			}
			
			break;
			
		default:
			parser->error = YES;
			break;
	}
}


NS_INLINE uint32_t totalSecondsForComponents(JXTimeCodeComponents components) {
	return (components.hours * 3600) + (components.minutes * 60) + components.seconds;
}

NS_INLINE CMTime convertComponentsToCMTime(JXTimeCodeComponents components) {
	uint32_t totalSeconds = totalSecondsForComponents(components);
	CMTime secondsTime = CMTimeMake(totalSeconds, 1);
	
	if (components.fractionalDigits == 0) {
		return secondsTime;
	}
	else {
		const int32_t timescaleForDigits[] = {0, 10, 100, 1000};
		const int32_t timeIndexPairCount = sizeof(timescaleForDigits)/sizeof(timescaleForDigits[0]);
		
		int32_t timescale;
		if (LIKELY(components.fractionalDigits < timeIndexPairCount)) {
			timescale = timescaleForDigits[components.fractionalDigits];
		} else {
			timescale = __exp10(components.fractionalDigits);
		}
		
		CMTime fractionalSecondsTime = CMTimeMake(components.fractional, timescale);
		
		CMTime time = CMTimeAdd(secondsTime, fractionalSecondsTime);
		
		return time;
	}
}
