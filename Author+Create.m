//
//  Author+Create.m
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Author+Create.h"
#import "NSString+Import.h"

@implementation Author (Create)

+ (Author *) findOrCreateforDict:(NSDictionary *)dict inManagedContext:(NSManagedObjectContext *)context
{
    NSString *uuid = dict[@"uuid"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Author"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    request.predicate = predicate;
    NSArray *result = [context executeFetchRequest:request error:nil];
    
    Author *author;
    if (result.count > 0) {
        author  = [result objectAtIndex:0];
        NSLog(@"Fount author for name %@ [count %lu]\n", uuid, result.count);
    } else {
        author = [NSEntityDescription insertNewObjectForEntityForName:@"Author"
                                               inManagedObjectContext:context];
        author.uuid = uuid;
        author.firstName = [NSString mkStringForJS:dict[@"firstName"]];
        author.lastName = [NSString mkStringForJS:dict[@"lastName"]];
        author.middleName = [NSString mkStringForJS:dict[@"middleName"]];
    }
    
    return author;
}


@end
