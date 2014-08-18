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
#import "Correspondence.h"


@interface NSString (Trimming)
- (NSString *) stringCleanForCD;
@end

@implementation NSString (Trimming)
- (NSString *) stringCleanForCD
{
    NSString *trimmedString = [self stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedString;
}

@end

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
    abstract.uuid = [json[@"uuid"] stringCleanForCD];
    abstract.title = [[json objectForKey:@"title"] stringCleanForCD];
    abstract.text = [[json objectForKey:@"abstract"] stringCleanForCD];
    abstract.acknoledgements = [[json objectForKey:@"acknowledgements"] stringCleanForCD];
    abstract.references = [[json objectForKey:@"refs"] stringCleanForCD];
    abstract.conflictOfInterests = [[json objectForKey:@"coi"] stringCleanForCD];
    abstract.doi = [json objectForKey:@"doi"];
    abstract.figid = [json[@"figid"] integerValue];
    abstract.altid = [json[@"altid"] integerValue];
    abstract.caption = json[@"caption"];
    
    NSString *session = [json objectForKey:@"session"];
    if (session) {
        abstract.topic = session;
    } else {
        abstract.topic = [json objectForKey:@"topic"];
    }
    
    NSNumber *nfigures = [json objectForKey:@"nfigures"];
    abstract.nfigures = [nfigures intValue];
    
    return abstract;
}



@end
