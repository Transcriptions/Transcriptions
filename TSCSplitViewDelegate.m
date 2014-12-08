//
//  TSCSplitViewDelegate.m
//  Transcriptions
//
//  Created by David Haselberger on 19/08/14.
//
//

#import "TSCSplitViewDelegate.h"

@implementation TSCSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 240)
    {
        proposedMinimumPosition = 240;
    }
    return proposedMinimumPosition;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

@end
