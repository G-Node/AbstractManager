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
    abstract.topic = [json objectForKey:@"topic"];
    abstract.frontid = [json objectForKey:@"frontid"];
    abstract.frontsubid = [json objectForKey:@"frontsubid"];
    
    NSNumber *nfigures = [json objectForKey:@"nfigures"];
    abstract.nfigures = [nfigures intValue];
    
    return abstract;
}



@end
