//
//  AbstractGroup.h
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _GroupType {
    GT_UNSORTED = 0,
    GT_I = 1,
    GT_W = 2,
    GT_T = 3,
    GT_F = 4
} GroupType;

@interface AbstractGroup : NSObject
@property (strong, nonatomic) NSMutableOrderedSet  *abstracts;
@property (readonly, nonatomic) NSString *name;
@property (nonatomic) GroupType type;
+ (AbstractGroup *) groupWithType:(GroupType) groupType;

@end