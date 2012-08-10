//
//  Abstract+JSON.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/9/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "Abstract+JSON.h"
#import "Author.h"
#import "Organization.h"
#import "Affiliation.h"
#import "Correspondence.h"

@implementation Abstract (JSON)
- (NSDictionary *) json
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [json setObject:[NSNumber numberWithInt:self.aid] forKey:@"id"];
    [json setObject:self.title forKey:@"title"];
    [json setObject:self.text forKey:@"abstract"];
    [json setObject:self.topic forKey:@"topic"];
    [json setObject:self.frontid forKey:@"frontid"];
    [json setObject:self.frontsubid forKey:@"frontsubid"];
    [json setObject:[NSNumber numberWithInt:self.nfigures] forKey:@"nfigures"];
    
    if (self.acknoledgements)
        [json setObject:self.acknoledgements forKey:@"acknowledgements"];
    
    if (self.references)
        [json setObject:self.references forKey:@"refs"];
    
    if (self.conflictOfInterests)
        [json setObject:self.conflictOfInterests forKey:@"coi"];
    
    NSMutableArray *authorArray = [NSMutableArray arrayWithCapacity:self.authors.count];
    NSMutableArray *corArray = [NSMutableArray arrayWithCapacity:self.correspondenceAt.count];
    
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
        
        for (Correspondence *cor in self.correspondenceAt) {
            if (cor.ofAuthor == author) {
                [epithet appendString:@"*"];
                [corArray addObject:cor.email];
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
    [json setObject:corArray forKey:@"correspondence"];
    
    return json;
}

@end
