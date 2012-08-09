//
//  Abstract+Create.m
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Abstract+Create.h"
#import "Author.h"
#import "Organization.h"
#import "Affiliation.h"

@implementation Abstract (Create)

+ (Abstract *) abstractForJSON:(NSDictionary *)json
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Abstract *abstract = [Abstract abstractForJSON:json withId:0 inManagedObjectContext:context];
    return abstract;
}

+ (Abstract *) abstractForJSON:(NSDictionary *)json
                        withId:(int32_t) abstractID
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Abstract *abstract = (Abstract *) [NSEntityDescription insertNewObjectForEntityForName:@"Abstract"
                                                                    inManagedObjectContext:context];
    
    abstract.aid = abstractID;
    abstract.title = [json objectForKey:@"title"];
    abstract.text = [json objectForKey:@"abstract"];
    abstract.acknoledgements = [json objectForKey:@"acknowledgements"];
    abstract.references = [json objectForKey:@"refs"];
    abstract.conflictOfInterests = [json objectForKey:@"coi"];
    
    return abstract;
}


- (NSDictionary *) json
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [json setObject:[NSNumber numberWithInt:self.aid] forKey:@"id"];
    [json setObject:self.title forKey:@"title"];
    [json setObject:self.text forKey:@"abstract"];
    
    if (self.acknoledgements)
        [json setObject:self.acknoledgements forKey:@"acknowledgements"];
    
    if (self.references)
        [json setObject:self.references forKey:@"refs"];
    
    if (self.conflictOfInterests)
        [json setObject:self.conflictOfInterests forKey:@"coi"];
    
    NSMutableArray *authorArray = [NSMutableArray arrayWithCapacity:self.authors.count];
    for (Author *author in self.authors) {
     
        NSMutableString *epithet = [[NSMutableString alloc] init];
        NSUInteger afcount = 0;
        for (NSUInteger i = 0; i < self.affiliations.count; i++) {
            Affiliation *affiliation = [self.affiliations objectAtIndex:i];
            if ([affiliation.ofAuthors containsObject:author]) {
                [epithet appendFormat:@"%s%lu", afcount > 0 ? "," : "", i+1];
                afcount++;
            }
        }
        
        NSDictionary *authorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    author.name, @"name",
                                    epithet, @"epithet", nil];
        [authorArray addObject:authorDict];
    }
    
    NSMutableArray *afArray = [NSMutableArray arrayWithCapacity:self.affiliations.count];
    for (int idx = 0; idx < self.affiliations.count; idx++) {
        Affiliation *affiliation = [self.affiliations objectAtIndex:idx];
        Organization *org = affiliation.toOrganization;
        NSMutableString *address = [[NSMutableString alloc] init];
        if (org.department)
            [address appendFormat:@"%@, %@, %@", org.department, org.name, org.country];
        else {
            [address appendFormat:@"%@, %@", org.name, org.country];
        }
        
        NSString *index = [NSString stringWithFormat:@"%d", idx+1];
        
        NSDictionary *afDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                address, @"address",
                                index, @"index", nil];
        [afArray addObject:afDict];
    }

    [json setObject:authorArray forKey:@"authors"];
    [json setObject:afArray forKey:@"affiliations"];
    
    return json;
}

@end
