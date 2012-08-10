//
//  Correspondence+Create.h
//  AbstractManager
//
//  Created by Christian Kellner on 8/9/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "Correspondence.h"

@interface Correspondence (Create)
+ (Correspondence *) correspondenceAt:(NSString *)email
                            forAuthor:(Author *)author
               inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *) parseText:(NSString *)text;
@end
