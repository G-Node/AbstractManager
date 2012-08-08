//
//  Author+Create.m
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Author+Create.h"

@implementation Author (Create)

+ (Author *) findOrCreateforName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Author"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    request.predicate = predicate;
    NSArray *result = [context executeFetchRequest:request error:nil];
    
    Author *author;
    if (result.count > 0) {
        author  = [result objectAtIndex:0];
        NSLog(@"Fount author for name %@ [count %lu]\n", name, result.count);
    } else {
        author = [NSEntityDescription insertNewObjectForEntityForName:@"Author"
                                               inManagedObjectContext:context];
        author.name = name;
    }
    
    return author;
}

@end
