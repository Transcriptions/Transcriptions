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

#import "TSCKeyBindingsController.h"
//#import <PTHotKey/PTHotKeyCenter.h>

@implementation TSCKeyBindingsController
{
    SRShortcutValidator *_validator;
}

#pragma mark SRRecorderControlDelegate
/*- (BOOL)recorderControl:(SRRecorderControl *)aRecorder canRecordShortcut:(SRShortcut *)aShortcut
{
    __autoreleasing NSError *error = nil;
    BOOL isTaken = [_validator validateShortcut:aShortcut error:&error];
	
		
	
    if (isTaken)
    {
        NSBeep();
		if (aRecorder.window)
		{
			[aRecorder presentError:error
					 modalForWindow:aRecorder.window
						   delegate:nil
				 didPresentSelector:NULL
						contextInfo:NULL];
		}
		else
		{
			[aRecorder presentError:error];
		}
    }
    
    return !isTaken;
}*/

/*- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] pause];
    return YES;
}*/

/*- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] resume];
}*/

/*- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder shouldUnconditionallyAllowModifierFlags:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    if ((aModifierFlags & aRecorder.requiredModifierFlags) != aRecorder.requiredModifierFlags)
        return NO;
    
    if ((aModifierFlags & aRecorder.allowedModifierFlags) != aModifierFlags)
        return NO;
    
    switch (aKeyCode)
    {
        case kVK_F1:
        case kVK_F2:
        case kVK_F3:
        case kVK_F4:
        case kVK_F5:
        case kVK_F6:
        case kVK_F7:
        case kVK_F8:
        case kVK_F9:
        case kVK_F10:
        case kVK_F11:
        case kVK_F12:
        case kVK_F13:
        case kVK_F14:
        case kVK_F15:
        case kVK_F16:
        case kVK_F17:
        case kVK_F18:
        case kVK_F19:
        case kVK_F20:
            return YES;
        default:
            return NO;
    }
}*/
- (BOOL)recorderControl:(SRRecorderControl *)aControl canRecordShortcut:(SRShortcut *)aShortcut
{
	__autoreleasing NSError *error = nil;
	BOOL isTaken = [_validator validateShortcutAgainstDelegate:aShortcut error:&error];
	if (isTaken)
	{
		NSBeep();
		if (aControl.window)
		{
			[aControl presentError:error
					 modalForWindow:aControl.window
						   delegate:nil
				 didPresentSelector:NULL
						contextInfo:NULL];
		}
		else
		{
			[aControl presentError:error];
		}
	}
	
	return !isTaken;

}

#pragma mark SRShortcutValidatorDelegate

- (BOOL)shortcutValidator:(SRShortcutValidator *)aValidator isShortcutValid:(SRShortcut *)aShortcut reason:(NSString * _Nullable * _Nonnull)outReason
{
    SRRecorderControl *recorder = (SRRecorderControl *)prefPane.firstResponder;
    if (![recorder isKindOfClass:[SRRecorderControl class]])
        return NO;

	NSDictionary* shortcut = [aShortcut dictionaryRepresentation];
	if(recorder != replayShortcutRecorder)
	{
		NSDictionary* x = (NSDictionary *)[replayShortcutRecorder objectValue];
		if([shortcut isEqualToDictionary:x])
		{
			*outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
			return YES;
		}
	}
	if(recorder != pauseShortcutRecorder)
	{
		NSDictionary* x = (NSDictionary *)[pauseShortcutRecorder objectValue];
		if([shortcut isEqualToDictionary:x])
		{
			*outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
			return YES;
		}
	}
	if(recorder != controlsShortcutRecorder)
	{
		NSDictionary* x = (NSDictionary *)[controlsShortcutRecorder objectValue];
		if([shortcut isEqualToDictionary:x])
		{
			*outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
			return YES;
		}
	}
	if(recorder != timestampShortcutRecorder)
	{
		NSDictionary* x = (NSDictionary *)[timestampShortcutRecorder objectValue];
		if([shortcut isEqualToDictionary:x])
		{
			*outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
			return YES;
		}
	}
	if(recorder != ffShortcutRecorder)
	{
		NSDictionary* x = (NSDictionary *)[ffShortcutRecorder objectValue];
		if([shortcut isEqualToDictionary:x])
		{
			*outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
			return YES;
		}
	}
	return NO;
	
}

- (BOOL)shortcutValidatorShouldCheckMenu:(SRShortcutValidator *)aValidator
{
    return YES;
}


#pragma mark NSObject




- (void)awakeFromNib
{

    [super awakeFromNib];
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];

    
    [replayMenuItem bind:@"keyEquivalent"
               toObject:defaults
            withKeyPath:@"values.replayItem"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [replayMenuItem bind:@"keyEquivalentModifierMask"
               toObject:defaults
            withKeyPath:@"values.replayItem"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];
    
	[fastForwardMenuItem bind:@"keyEquivalent"
			   toObject:defaults
			withKeyPath:@"values.fastForwardItem"
				options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
	[fastForwardMenuItem bind:@"keyEquivalentModifierMask"
			   toObject:defaults
			withKeyPath:@"values.fastForwardItem"
				options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];
    
    [playPauseMenuItem bind:@"keyEquivalent"
                toObject:defaults
             withKeyPath:@"values.playPauseItem"
                 options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [playPauseMenuItem bind:@"keyEquivalentModifierMask"
                toObject:defaults
             withKeyPath:@"values.playPauseItem"
                 options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];
    
    
    [controlsMenuItem bind:@"keyEquivalent"
                   toObject:defaults
                withKeyPath:@"values.controlsItem"
                    options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [controlsMenuItem bind:@"keyEquivalentModifierMask"
                   toObject:defaults
                withKeyPath:@"values.controlsItem"
                    options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];
    
    
    [timestampMenuItem bind:@"keyEquivalent"
                  toObject:defaults
               withKeyPath:@"values.timestampItem"
                   options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [timestampMenuItem bind:@"keyEquivalentModifierMask"
                  toObject:defaults
               withKeyPath:@"values.timestampItem"
                   options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];
    
	
    [replayShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.replayItem"
                                options:nil];
    [pauseShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.playPauseItem"
                                options:nil];
	[ffShortcutRecorder bind:NSValueBinding
							   toObject:defaults
							withKeyPath:@"values.fastForwardItem"
								options:nil];
    [controlsShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.controlsItem"
                                options:nil];
    [timestampShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.timestampItem"
                                options:nil];
    
    _validator = [[SRShortcutValidator alloc] initWithDelegate:self];
	//_validator

	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"replayItem"])
	{
		[self setKeyEquivalent:@"1" withModifierMask:NSEventModifierFlagControl ofMenuItem:replayMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"playPauseItem"])
	{
		[self setKeyEquivalent:@"2" withModifierMask:NSEventModifierFlagControl ofMenuItem:playPauseMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"fastForwardItem"])
	{
		[self setKeyEquivalent:@"3" withModifierMask:NSEventModifierFlagControl ofMenuItem:playPauseMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"controlsItem"])
	{
		[self setKeyEquivalent:@"4" withModifierMask:NSEventModifierFlagControl ofMenuItem:controlsMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"timestampItem"])
	{
		[self setKeyEquivalent:@"t" withModifierMask:NSEventModifierFlagControl ofMenuItem:timestampMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"])
	{
		[[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"autoTimestamp"];
	}
	
}



- (void)setKeyEquivalent:(NSString*)keyEquivalent withModifierMask:(unsigned int)flags ofMenuItem:(NSMenuItem*)aMenuItem;
{
		
	aMenuItem.keyEquivalent = keyEquivalent;
	aMenuItem.keyEquivalentModifierMask = flags;
		
}







@end
