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
#import "Organization+Format.h"
#import "Affiliation.h"
#import "Correspondence.h"
#import "Reference.h"

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

    [html appendString:@"<html><head>"];
    [html appendString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"Abstract.css\" />"];
    [html appendString:@"<meta name='viewport' content='initial-scale=1.0,maximum-scale=10.0'/>"];
    [html appendString:@"</head><body>"];
    //[html appendFormat:@"<div id=\"aid\">%@</div>", [self formatId:YES]];
    [html appendFormat:@"<div id=\"topic\">%@</div>", self.topic];
    [html appendFormat:@"<div><h1 id=\"title\">%@</h2></div>", self.title];

    [html appendString:@"<div><h2 id=\"author\">"];
    for (Author *author in self.authors) {
        [html appendFormat:@"%@", [author formatName]];

        [html appendFormat:@"<sup id=\"epithat\">"];
        NSUInteger count = 0;
        for (short i = 0; i < self.affiliations.count; i++) {
            Affiliation *affiliation = [self.affiliations objectAtIndex:i];
            if ([affiliation.ofAuthors containsObject:author]) {
                [html appendFormat:@"%s%u", count != 0 ? ", " : "", i+1];
                count++;
            }
        }

        for (Correspondence *cor in self.correspondenceAt) {
            if (cor.ofAuthor == author)
                [html appendString:@"*"];
        }

        [html appendFormat:@"</sup><br/>"];

    }
    [html appendString:@"</h2></div><div id=\"affiliations\">"];
    [html appendFormat:@"<ol>"];

    for (Affiliation *affiliation in self.affiliations) {
        Organization *org = affiliation.toOrganization;
        [html appendFormat:@"<li>%@</li>", [org mkString]];
    }

    [html appendFormat:@"</ol>"];
    for (Correspondence *cor in self.correspondenceAt) {
        [html appendFormat:@"</div><div id=\"correspondence\"><sup>*</sup> %@ ", cor.email];
    }
    [html appendString:@"</div><br/>"];

    [html appendFormat:@"<div><p id=\"abstract\">%@</p></div>", [self.text formatHTML]];

    if (self.acknoledgements && self.acknoledgements.length)
        [html appendFormat:@"<div class=\"appendix\"><h4>Acknowledgements</h4><p>%@</p></div>", [self.acknoledgements formatHTML]];

    if (self.references && self.references.count) {
        [html appendFormat:@"<div class=\"appendix\"><p><h4>References</h4><ol>"];
        for (Reference *ref in self.references) {
            NSString *link = nil;
            if (ref.link) {
                link = ref.link;
            } else if (ref.doi) {
                link = ref.doi;
            } else {
                link = @"";
            }

            [html appendString:@"<li>"];
            [html appendFormat:@"<a href=\"%@\">%@</a>", link, ref.text];
            if (ref.doi) {
                [html appendFormat:@"<a href=\"http://dx.doi.org/%@\">%@</a>", ref.doi, ref.doi];
            }
            [html appendString:@"</li>"];

        }
        [html appendString:@"</ol></div>"];
    }

    NSArray *legitFormats = @[ @"tiff", @"png", @"jpeg", @"pdf"];
    if (self.nfigures) {
        NSString *figID = [NSString stringWithFormat:@"%03d", self.figid];
        NSLog(@"figure path: %@", figID);

        __block NSString *fullpath = @"";

        [legitFormats enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            fullpath = [NSString stringWithFormat:@"%@.%@", figID, obj];
            NSString *testPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fullpath];
            *stop = [[NSFileManager defaultManager] fileExistsAtPath:testPath];
        }];

        NSString *caption = self.caption;
        if ([caption hasPrefix:@"Figure 1"]) {
            caption = [caption substringFromIndex:8];
        }

        [html appendFormat:@"<div class=\"figure\"><img src=\"%@\" /><p>Figure 1:%@<p></div><br/>", fullpath, caption];
    }

    [html appendFormat:@"<div>doi: <a href=\"http://dx.doi.org/%@\">%@</a></div><br/>", self.doi, self.doi];
    [html appendString:@"</body></html>"];

    
    return html;
}

@end
