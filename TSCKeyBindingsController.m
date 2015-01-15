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
#import <PTHotKey/PTHotKeyCenter.h>

@implementation TSCKeyBindingsController
{
    SRValidator *_validator;
}

#pragma mark SRRecorderControlDelegate
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canRecordShortcut:(NSDictionary *)aShortcut
{
    __autoreleasing NSError *error = nil;
    BOOL isTaken = [_validator isKeyCode:[aShortcut[SRShortcutKeyCode] unsignedShortValue] andFlagsTaken:[aShortcut[SRShortcutModifierFlagsKey] unsignedIntegerValue] error:&error];
    
    if (isTaken)
    {
        NSBeep();
    }
    
    return !isTaken;
}

- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] pause];
    return YES;
}

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] resume];
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder shouldUnconditionallyAllowModifierFlags:(NSUInteger)aModifierFlags forKeyCode:(unsigned short)aKeyCode
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
}


#pragma mark SRValidatorDelegate

- (BOOL)shortcutValidator:(SRValidator *)aValidator isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSUInteger)aFlags reason:(NSString **)outReason
{
#define IS_TAKEN(aRecorder) (recorder != (aRecorder) && SRShortcutEqualToShortcut(shortcut, [(aRecorder) objectValue]))
    SRRecorderControl *recorder = (SRRecorderControl *)prefPane.firstResponder;
    
    if (![recorder isKindOfClass:[SRRecorderControl class]])
        return NO;
    
    NSDictionary *shortcut = SRShortcutWithCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
    
    if (IS_TAKEN(replayShortcutRecorder) ||
        IS_TAKEN(pauseShortcutRecorder) ||
        IS_TAKEN(controlsShortcutRecorder) ||
        IS_TAKEN(timestampShortcutRecorder))
    {
        *outReason = @"it's already used. To use this shortcut, first remove or change the other shortcut";
        return YES;
    }
    else
        return NO;
#undef IS_TAKEN
}

- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator
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
    [controlsShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.controlsItem"
                                options:nil];
    [timestampShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.timestampItem"
                                options:nil];
    
    _validator = [[SRValidator alloc] initWithDelegate:self];

	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"replayItem"])
	{
		[self setKeyEquivalent:@"1" withModifierMask:NSControlKeyMask ofMenuItem:replayMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"playPauseItem"])
	{
		[self setKeyEquivalent:@"2" withModifierMask:NSControlKeyMask ofMenuItem:playPauseMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"controlsItem"])
	{
		[self setKeyEquivalent:@"3" withModifierMask:NSControlKeyMask ofMenuItem:controlsMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"timestampItem"])
	{
		[self setKeyEquivalent:@"t" withModifierMask:NSControlKeyMask ofMenuItem:timestampMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"])
	{
		[[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"autoTimestamp"];
	}
	
}



- (void)setKeyEquivalent:(NSString*)keyEquivalent withModifierMask:(unsigned int)flags ofMenuItem:(NSMenuItem*)aMenuItem;
{
		
	[aMenuItem setKeyEquivalent:keyEquivalent];
	[aMenuItem setKeyEquivalentModifierMask:flags];
		
}







@end
