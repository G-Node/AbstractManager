//
//  Abstract+HTML.m
//  GCA
//
//  Created by Christian Kellner on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Abstract+HTML.h"
#import "Author.h"
#import "Author+Format.h"
#import "Organization.h"
#import "Affiliation.h"
#import "Correspondence.h"

@implementation NSString(HTML)

- (NSString *) formatHTML
{
    return [self stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
}

@end

@implementation Abstract (HTML)

- (NSString *)renderHTML
{
    NSMutableString *html = [[NSMutableString alloc] init];
    
    [html appendString:@"<html><body>"];
    [html appendFormat:@"<div><small>%@</small></div>", self.topic];
    [html appendFormat:@"<div><h2>%@</h2></div>", self.title];
    
    [html appendString:@"<div><h3>"];
    for (Author *author in self.authors) {
        [html appendFormat:@"%@", [author formatName]];
        
        [html appendFormat:@"<sup>"];
        for (NSUInteger i = 0; i < self.affiliations.count; i++) {
            Affiliation *affiliation = [self.affiliations objectAtIndex:i];
            if ([affiliation.ofAuthors containsObject:author]) {
                [html appendFormat:@"%ld ", i+1];
            }
        }
        
        for (Correspondence *cor in self.correspondenceAt) {
            if (cor.ofAuthor == author)
                [html appendString:@"*"];
        }
        
        [html appendFormat:@"</sup><br/>"];
        
    }
    [html appendString:@"</h3></div>"];
    
    for (NSUInteger i = 0; i < self.affiliations.count; i++) {
        Affiliation *affiliation = [self.affiliations objectAtIndex:i];
        Organization *org = affiliation.toOrganization;
        
        if (org.department) {
            if (org.section) {
                [html appendFormat:@"<sup>%ld</sup> %@, %@, %@, %@<br/>", i+1, org.section, org.department, org.name, org.country];
            } else {
                [html appendFormat:@"<sup>%ld</sup> %@, %@, %@<br/>", i+1, org.department, org.name, org.country];
            }
        }
        else {
            [html appendFormat:@"<sup>%ld</sup> %@, %@<br/>", i+1, org.name, org.country];
        }
    }
    
    for (Correspondence *cor in self.correspondenceAt) {
            [html appendFormat:@"<sup>*</sup> %@ ", cor.email];
    }
    [html appendString:@"<br/>"];
    
    [html appendFormat:@"<p>%@</p>", [self.text formatHTML]];
    
    if (self.acknoledgements)
        [html appendFormat:@"<p><h4>Acknowledgements</h4>%@</p>", [self.acknoledgements formatHTML]];
    
    if (self.references)
        [html appendFormat:@"<p><h4>References</h4>%@</p>", [self.references formatHTML]];
    
    [html appendFormat:@"<div><small>DOI: %@</small></div>", self.doi];
    [html appendFormat:@"<div><small>uuid: %@</small></div>", self.uuid];
    [html appendString:@"</body></html>"];
    
    return html;
}

@end
