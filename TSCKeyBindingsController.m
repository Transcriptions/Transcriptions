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


@implementation TSCKeyBindingsController


- (void)awakeFromNib
{
		
	

	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder rePlayKeyBinding"])
	{
		[self setKeyEquivalent:@"1" withModifierMask:NSControlKeyMask ofMenuItem:replayMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder pauseKeyBinding"])
	{
		[self setKeyEquivalent:@"2" withModifierMask:NSControlKeyMask ofMenuItem:pauseMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder controlsKeyBinding"])
	{
		[self setKeyEquivalent:@"3" withModifierMask:NSControlKeyMask ofMenuItem:controlsMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder timestampKeyBinding"])
	{
		[self setKeyEquivalent:@"t" withModifierMask:NSControlKeyMask ofMenuItem:timestampMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder gotoBeginningKeyBinding"])
	{
		[self setKeyEquivalent:@"4" withModifierMask:NSControlKeyMask ofMenuItem:gotoBeginningMenuItem];
	}
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder gotoEndKeyBinding"])
	{
		[self setKeyEquivalent:@"5" withModifierMask:NSControlKeyMask ofMenuItem:gotoEndMenuItem];
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



/*- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason
{
	BOOL taken = NO;
	
	return taken;
}*/





@end
