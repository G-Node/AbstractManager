//
//  JSONImporer.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/28/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "JSONImporter.h"

#import "Abstract.h"
#import "Abstract+Create.h"
#import "Abstract+HTML.h"
#import "Author.h"
#import "Author+Create.h"
#import "Affiliation.h"
#import "Organization+Create.h"
#import "Correspondence+Create.h"
#import "AbstractGroup.h"
#import "Reference.h"
#import "NSString+Import.h"
#import "Figure.h"

@implementation JSONImporter
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

            author.isAffiliatedTo = afbuilder;
        }
        
        if (authorSet.count > 0)
            abstract.authors = authorSet;

        //References
        NSMutableOrderedSet *refs = [[NSMutableOrderedSet alloc] init];
        for(NSDictionary *refDict in absDict[@"references"]) {
            Reference *ref = [NSEntityDescription insertNewObjectForEntityForName:@"Reference"
                                                           inManagedObjectContext:context];
            ref.uuid = [NSString mkStringForJS:refDict[@"uuid"]];
            ref.link = [NSString mkStringForJS:refDict[@"link"]];
            ref.doi = [NSString mkStringForJS:refDict[@"doi"]];
            ref.text = [NSString mkStringForJS:refDict[@"text"]];

            [refs addObject:ref];
        }

        abstract.references = refs;

        //figures
        NSMutableOrderedSet *figures = [[NSMutableOrderedSet alloc] init];
        for(NSDictionary *figDict in absDict[@"figures"]) {
            Figure *figure = [NSEntityDescription insertNewObjectForEntityForName:@"Figure"
                                                           inManagedObjectContext:context];
            figure.uuid = figDict[@"uuid"];
            figure.caption = [NSString mkStringForJS:figDict[@"caption"]];
            figure.url = [NSString mkStringForJS:figDict[@"URL"]];
            [figures addObject:figure];
        }
        
        abstract.figures = figures;
    }
    
    return YES;
}



@end
