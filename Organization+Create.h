//
//  Organization+Create.h
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Organization.h"

@interface Organization (Create)
+ (Organization *) findOrCreateForDict:(NSDictionary *)json inManagedContext:(NSManagedObjectContext *)contex;
+ (Organization *) findOrCreateForString:(NSString *)string inManagedContext:(NSManagedObjectContext *)contex;
@end
