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
#import "NSString+Import.h"

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
    abstract.title = [NSString mkStringForJS:json[@"title"]];
    abstract.text = [NSString mkStringForJS:json[@"text"]];
    abstract.acknoledgements = [NSString mkStringForJS:json[@"acknowledgements"]];
    abstract.conflictOfInterests = [NSString mkStringForJS:json[@"conflictOfInterest"]];
    abstract.doi = [NSString mkStringForJS:json[@"doi"]];
    abstract.topic = [NSString mkStringForJS:json[@"topic"]];

    return abstract;
}



@end
