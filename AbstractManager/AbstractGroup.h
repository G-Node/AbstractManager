//
//  AbstractGroup.h
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef uint8 GroupType;

@interface AbstractGroup : NSObject
@property (strong, nonatomic) NSMutableOrderedSet  *abstracts;
@property (strong, nonatomic) NSString *name;
@property (nonatomic) GroupType type;

+ (AbstractGroup *) groupWithType:(GroupType) groupType;
+ (AbstractGroup *) groupWithUID:(uint8)uid andName:(NSString *)name;

@end