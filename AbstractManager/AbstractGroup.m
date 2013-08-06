//
//  AbstractGroup.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "AbstractGroup.h"

@implementation AbstractGroup
@synthesize abstracts = _abstracts;
@synthesize type = _type;

+ (AbstractGroup *) groupWithType:(GroupType)groupType
{
    AbstractGroup *group = [[AbstractGroup alloc] init];
    group.type = groupType;
    return group;
}

- (NSString *)name {
    switch (self.type) {
        case GT_UNSORTED:
            return @"Unsorted";
            break;
        case GT_I:
            return @"Invited Talk";
            break;
        case GT_W:
            return @"Wednesday";
            break;
        case GT_T:
            return @"Thursday";
            break;
        case GT_F:
            return @"Friday";
            break;
    }
}
- (NSMutableOrderedSet *)abstracts
{
    if (_abstracts == nil) {
        _abstracts = [[NSMutableOrderedSet alloc] init];
    }
    return _abstracts;
}

@end