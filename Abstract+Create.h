//
//  Abstract+Create.h
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Abstract.h"

@interface Abstract (Create)

+ (Abstract *) abstractForJSON:(NSDictionary *)json inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Abstract *) abstractForJSON:(NSDictionary *)json
                        withId:(int32_t) abstractID
        inManagedObjectContext:(NSManagedObjectContext *)context;
- (NSDictionary *) json;
@end
