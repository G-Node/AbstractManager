//
//  Organization+Create.m
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Organization+Create.h"
#import "NSString+Import.h"

@implementation NSArray (Trimming)

- (NSString *) trimedStringAtIndex:(NSUInteger)index
{
    NSString *str = [self objectAtIndex:index];
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@implementation Organization (Create)

+ (Organization *) findOrCreateForDict:(NSDictionary *)dict inManagedContext:(NSManagedObjectContext *)context
{
    NSString *uuid = dict[@"uuid"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Organization"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    request.predicate = predicate;
    NSArray *result = [context executeFetchRequest:request error:nil];

    Organization *org;
    if (result.count > 0) {
        org  = [result objectAtIndex:0];
        NSLog(@"Fount Org[count %lu]\n", result.count);
    } else {
        org = [NSEntityDescription insertNewObjectForEntityForName:@"Organization"
                                               inManagedObjectContext:context];
        for (NSString *key in dict) {
            NSString *value = [dict objectForKey:key];

            if ([key isEqualToString:@"position"]) {
                continue;
            }

            [org setValue:[NSString mkStringForJS:value] forKey:key];
        }
    }
    return org;
}


+ (Organization *) findOrCreateForString:(NSString *)string inManagedContext:(NSManagedObjectContext *)contex
{
    Organization *org;
    
    NSArray *parts = [string componentsSeparatedByString:@","];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSUInteger idx = 0;
    
    if (parts.count > 3) {
        NSUInteger nelm = parts.count - 3;
        NSRange range  = NSMakeRange(0, nelm+1);
        NSArray *left = [parts subarrayWithRange:range];
        NSString *section = [left componentsJoinedByString:@", "];
        [dict setObject:section forKey:@"section"];
        idx += nelm;
    }
    
    if (parts.count > 2) {
        [dict setObject:[parts trimedStringAtIndex:idx++] forKey:@"department"];
    }
    
    if (parts.count > 1) {
        [dict setObject:[parts trimedStringAtIndex:idx++] forKey:@"name"];
        [dict setObject:[parts trimedStringAtIndex:idx++] forKey:@"country"];
    }
    
    org = [Organization findOrCreateForDict:dict inManagedContext:contex];
    return org;
}

@end
