//
//  Abstract+XML.m
//  AbstractManager
//
//  Created by Christian Kellner on 8/9/12.
//  Copyright (c) 2012 G-Node. All rights reserved.
//

#import "Abstract+XML.h"
#import "Affiliation.h"
#import "Author.h"
#import "Organization.h"

@implementation Abstract (XML)
-(NSXMLNode *) xml
{
    NSXMLElement *parent =
    (NSXMLElement *)[NSXMLNode elementWithName:@"abstract"];
    
    NSXMLNode *node;
    node = [NSXMLNode elementWithName:@"title" stringValue:self.title];
    [parent addChild:node];
    
    NSXMLNode *authors = [NSXMLNode elementWithName:@"authors"];
    [parent addChild:authors];
    
    for (Author *author in self.authors) {
        node = [NSXMLNode elementWithName:@"author" stringValue:author.name];
        
        NSMutableString *epithet = [[NSMutableString alloc] init];
        for (NSUInteger i = 0; i < self.affiliations.count; i++) {
            Affiliation *affiliation = [self.affiliations objectAtIndex:i];
            if ([affiliation.ofAuthors containsObject:author]) {
                [epithet appendFormat:@"%s%lu", i > 0 ? "," : "", i+1];
            }
        }
        
        NSXMLNode *attr =  [NSXMLNode attributeWithName:@"epithet"
                                            stringValue:epithet];
        [((NSXMLElement *) node) addAttribute:attr];
        [((NSXMLElement *) authors) addChild:node];
    }
    
    for (int idx = 0; idx < self.affiliations.count; idx++) {
        Affiliation *affiliation = [self.affiliations objectAtIndex:idx];
        Organization *org = affiliation.toOrganization;
        NSMutableString *str = [[NSMutableString alloc] init];
        if (org.department)
            [str appendFormat:@"%@, %@, %@", org.department, org.name, org.country];
        else {
            [str appendFormat:@"%@, %@<br/>", org.name, org.country];
        }
        
        node = [NSXMLNode elementWithName:@"affiliations" stringValue:str];
        NSXMLNode *attr =  [NSXMLNode attributeWithName:@"index"
                                            stringValue:[NSString stringWithFormat:@"%d", idx+1]];
        [((NSXMLElement *) node) addAttribute:attr];
    }
    node = [NSXMLNode elementWithName:@"text" stringValue:self.text];
    [parent addChild:node];
    
    if (self.references) {
        node = [NSXMLNode elementWithName:@"refs" stringValue:self.references];
        [parent addChild:node];
    }
    
    if (self.acknoledgements) {
        node = [NSXMLNode elementWithName:@"acknowledgements" stringValue:self.acknoledgements];
        [parent addChild:node];
    }
    
    if (self.conflictOfInterests) {
        node = [NSXMLNode elementWithName:@"coi" stringValue:self.conflictOfInterests];
        [parent addChild:node];
    }
    
    return parent;
}
@end
