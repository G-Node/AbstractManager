//
//  JSONImporer.h
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONImporter : NSObject
-(id) initWithContext:(NSManagedObjectContext *)context;
-(BOOL) importAbstracts:(NSData *)data intoGroups:(NSArray *)groups;

@property (nonatomic, strong) NSManagedObjectContext *context;
@end
