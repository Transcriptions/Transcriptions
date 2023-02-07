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

#import "TSCArrayController.h"


@implementation TSCArrayController


- (void)awakeFromNib
{
	NSError *error;
	NSData *theData=[[NSUserDefaults standardUserDefaults] dataForKey:@"substitutionArray"];
	NSSet *classes = [NSSet setWithObjects:[NSArray class], [NSMutableDictionary class], [NSAttributedString class], [NSString class], nil];
		if (theData != nil){
			[self addObjects:(NSArray *)[NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:[[NSUserDefaults standardUserDefaults] dataForKey:@"substitutionArray"] error:&error]];
		}
}


- (void)add:(id)sender
{
	NSError *error;
	[super add:sender];
	NSData* saveData = [NSKeyedArchiver archivedDataWithRootObject:self.arrangedObjects requiringSecureCoding:false error:&error];
	[[NSUserDefaults standardUserDefaults] setObject:saveData forKey:@"substitutionArray"];
}

- (void)remove:(id)sender
{
	NSError *error;
	[super remove:sender];
	NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:self.arrangedObjects requiringSecureCoding:false error:&error];
	[[NSUserDefaults standardUserDefaults] setObject:saveData forKey:@"substitutionArray"];
}

- (void)objectDidEndEditing:(id)editor
{
	NSError *error;
	[super objectDidEndEditing:editor];
	NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:self.arrangedObjects requiringSecureCoding:false error:&error];
	[[NSUserDefaults standardUserDefaults] setObject:saveData forKey:@"substitutionArray"];
}


@end
