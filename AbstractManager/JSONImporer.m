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
#import "Abstract+JSON.h"
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

            NSString *type = [absDict objectForKey:@"type"];
            if ([type isEqualToString:@"Poster"]) {
                group = [groups lastObject];
                abstractIndex = (int32_t) group.abstracts.count;
                aid = abstractIndex + 1;
                
            } else {
                group = [groups objectAtIndex:0];
                abstractIndex = (int32_t) group.abstracts.count;
                aid = (abstractIndex + 1)| (1 << 16); // was GT_I FIXME
            }
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
        
        // Author
        NSArray *authors = [absDict objectForKey:@"authors"];
        
        NSMutableOrderedSet *authorSet = [[NSMutableOrderedSet alloc] init];
        for (NSDictionary *authorDict in authors) {
            NSString *name = [authorDict objectForKey:@"name"];
            Author *author = [Author findOrCreateforName:name inManagedContext:context];
            [authorSet addObject:author];
        }
        
        if (authorSet.count > 0)
            abstract.authors = authorSet;
        
        //Correspondences
        NSArray *corr;
        id corEntity = [absDict objectForKey:@"correspondence"];
        if ([corEntity isKindOfClass:[NSString class]]) {
            corr = [Correspondence parseText:corEntity];
        } else if ([corEntity isKindOfClass:[NSArray class]]) {
            corr = corEntity;
        }
        
        NSMutableSet *corrSet = [[NSMutableSet alloc] init];
        NSUInteger corIdx = 0;
        for (NSString *email in corr) {
            
            for (NSUInteger i = corIdx; i < authors.count; i++) {
                NSDictionary *authorDict = [authors objectAtIndex:i];
                BOOL isCorresponding;
                NSString *epithet = [authorDict objectForKey:@"epithet"];
                if (epithet) {
                    isCorresponding = [epithet hasSuffix:@"*"];
                } else {
                    isCorresponding = [authorDict objectForKey:@"corresponding"] != nil;
                }
                
                if (isCorresponding) {
                    Author *author = [abstract.authors objectAtIndex:i];
                    Correspondence *cor = [Correspondence correspondenceAt:email
                                                                 forAuthor:author
                                                    inManagedObjectContext:context];
                    [corrSet addObject:cor];
                    corIdx = i + 1;
                    break;
                }
            }
        }
        
        if (corrSet)
            abstract.correspondenceAt = corrSet;
        
        // Affiliations
        id afEntity = [absDict objectForKey:@"affiliations"];
        NSDictionary *afDict;
        
        if ([afEntity isKindOfClass:[NSArray class]]) {
            NSMutableDictionary *afDictBuilder = [[NSMutableDictionary alloc] initWithCapacity:[afEntity count]];
            
            [afEntity enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *address = [obj objectForKey:@"address"];
                [afDictBuilder setObject:address forKey:[NSString stringWithFormat:@"%lu", idx+1]];
            }];
            afDict = afDictBuilder;
        } else {
            afDict = [absDict objectForKey:@"affiliations"];
        }
        
        NSMutableOrderedSet *affiliations = [[NSMutableOrderedSet alloc] init];
        NSUInteger index = 1;
        for (NSUInteger afIdx = 1; afIdx <= afDict.count; afIdx++) {
            NSString *value = [afDict objectForKey:[NSString stringWithFormat:@"%lu", afIdx]];
            Organization *orga = [Organization findOrCreateForString:value inManagedContext:context];
            
            Affiliation *affiliation = [NSEntityDescription insertNewObjectForEntityForName:@"Affiliation" inManagedObjectContext:context];
            
            affiliation.toOrganization = orga;
            
            NSMutableSet *afAuthors = [[NSMutableSet alloc] init];
            for (NSUInteger idxAuthor = 0; idxAuthor < authors.count; idxAuthor++) {
                NSDictionary *authorDict = [authors objectAtIndex:idxAuthor];
                
                NSString *epithet = [authorDict objectForKey:@"epithet"];
                NSArray *afArray;

                if (epithet) {
                    NSArray *compoments = [epithet componentsSeparatedByString:@","];
                    NSMutableArray *compArray = [[NSMutableArray alloc] initWithCapacity:[compoments count]];
                    
                    [compoments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *c = (obj);
                        if ([c hasSuffix:@"*"]) {
                            c = [c substringToIndex:[c length] - 1];
                        }
                        
                     NSNumber *num = [NSNumber numberWithInteger:[c integerValue]];
                     if (num) {
                         [compArray addObject:num];
                     } else {
                         NSLog(@"XXX Not a number!");
                     }
                    }];
                    
                    afArray = compArray;
                } else {
                    afArray = [authorDict objectForKey:@"affiliations"];
                }
                
                for (NSNumber *afNum in afArray) {
                    if ([afNum unsignedIntegerValue] == index) {
                        [afAuthors addObject:[authorSet objectAtIndex:idxAuthor]];
                        break;
                    }
                }
            }
            
            affiliation.ofAuthors = afAuthors;
            
            [affiliations addObject:affiliation];
            index++;
        }
        
        abstract.affiliations = affiliations;
    }
    
    return YES;
}



@end
