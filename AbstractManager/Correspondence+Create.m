//
//  Correspondence+Create.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/9/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "Correspondence+Create.h"
#import "Author.h"

@implementation Correspondence (Create)
+ (Correspondence *) correspondenceAt:(NSString *)email
                            forAuthor:(Author *)author
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    Correspondence *corr = (Correspondence *) [NSEntityDescription insertNewObjectForEntityForName:@"Correspondence"
                                                                            inManagedObjectContext:context];
    
    corr.email = email;
    corr.ofAuthor = author;
    return corr;
}

+ (NSArray *) parseText:(NSString *)text
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray *comps = [line componentsSeparatedByString:@","];
        
        if (comps != nil && comps.count > 2) {
            NSString *email = [comps lastObject];
            email = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [array addObject:email];
        }
    }];
    
    return array;
}

@end
