//
//  Author+Create.h
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Author.h"

@interface Author (Create)
+ (Author *) findOrCreateforName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context;
@end
