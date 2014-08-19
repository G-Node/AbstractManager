//
//  JSONImporer.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "JSONImporer.h"

#import "Abstract.h"
#import "Abstract+Create.h"
#import "Abstract+HTML.h"
#import "Author.h"
#import "Author+Create.h"
#import "Affiliation.h"
#import "Organization+Create.h"
#import "Correspondence+Create.h"
#import "AbstractGroup.h"

@implementation JSONImporer
@synthesize context = _context;

-(id) initWithContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        self.context = context;
    }
    
    return self;
}

- (BOOL) importAbstracts:(NSData *)data intoGroups:(NSArray *)groups
{
    id list = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![list isKindOfClass:[NSArray class]]) {
        NSLog(@"NOT A ARRAY!\n");
        return NO;
    }
    
    NSManagedObjectContext *context = self.context;
    NSArray *abstracts = (NSArray *) list;
    
    for (NSDictionary *absDict in abstracts) {
        int32_t aid;
        
        AbstractGroup *group = nil;
        int32_t abstractIndex = 0;
        
        NSString *idStr = [absDict objectForKey:@"id"];
        if (idStr) {
            aid = (int32_t) [idStr integerValue];
            NSUInteger ngroups = groups.count;
            NSUInteger groupIndex = ((aid & (0xFFFF << 16)) + ngroups-1) % ngroups;
            group = [groups objectAtIndex:groupIndex];
            abstractIndex = (aid & 0xFFFF) - 1;
        } else {
            group = [groups lastObject];
            abstractIndex = (int32_t) group.abstracts.count;
            aid = abstractIndex + 1;
        }
        
        NSString *doi = [absDict objectForKey:@"doi"];
        if ([doi isEqualToString:@"none"]) {
            doi = nil;
        }
        
        if (doi) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Abstract"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"doi == %@", doi];
            request.predicate = predicate;
            NSArray *result = [context executeFetchRequest:request error:nil];
            
            if (result.count > 0) {
                //NSLog(@"FOUND: %@\n", [absDict objectForKey:@"title"]);
                continue;
            }
        }
        
        Abstract *abstract = [Abstract abstractForJSON:absDict withId:aid inManagedObjectContext:context];
        NSLog(@"NEW: %@\n", [absDict objectForKey:@"title"]);
        if (abstractIndex > [group.abstracts count]) {
            NSLog(@"%d,%ld", aid, group.abstracts.count);
            //FIXME assert bigger then?
            //NSAssert(abstractIndex-1 == group.abstracts.count, @"Input out of order");
            [group.abstracts addObject:abstract];
        } else {
            [group.abstracts insertObject:abstract atIndex:abstractIndex];
        }
        NSLog(@"N: %d %ld %@\n", abstractIndex, group.abstracts.count, group.name);

        
        // Affiliations
        id afEntity = [absDict objectForKey:@"affiliations"];

        if(![afEntity isKindOfClass:[NSArray class]]) {
            NSLog(@"Error in format: Affiliations is not an array");
            continue;
        }

        NSMutableOrderedSet *affiliations = [[NSMutableOrderedSet alloc] init];
        for (NSDictionary *afDict in afEntity) {
            Organization *orga = [Organization findOrCreateForDict:afDict inManagedContext:context];
            Affiliation *affiliation = [NSEntityDescription insertNewObjectForEntityForName:@"Affiliation"
                                                                     inManagedObjectContext:context];
            affiliation.toOrganization = orga;
            [affiliations addObject:affiliation];
        }

        abstract.affiliations = affiliations;

        // Author
        NSArray *authors = [absDict objectForKey:@"authors"];
        
        NSMutableOrderedSet *authorSet = [[NSMutableOrderedSet alloc] init];
        for (NSDictionary *authorDict in authors) {
            Author *author = [Author findOrCreateforDict:authorDict
                                        inManagedContext:context];
            [authorSet addObject:author];

            NSMutableSet *afbuilder = [[NSMutableSet alloc] init];
            NSArray *affiliated = authorDict[@"affiliations"];
            for (NSNumber *affid in affiliated) {
                NSUInteger idx = [affid unsignedIntegerValue];
                Affiliation *affiliation = [affiliations objectAtIndex:idx];
                [afbuilder addObject:affiliation];
            }

            author.isAffiliatedTo = [afbuilder copy];
        }
        
        if (authorSet.count > 0)
            abstract.authors = authorSet;


    }
    
    return YES;
}



@end
