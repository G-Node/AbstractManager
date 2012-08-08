//
//  Abstract+Create.m
//  GCA
//
//  Created by Christian Kellner on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Abstract+Create.h"

@implementation Abstract (Create)

+ (Abstract *) abstractForJSON:(NSDictionary *)json
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Abstract *abstract = (Abstract *) [NSEntityDescription insertNewObjectForEntityForName:@"Abstract"
                                                                    inManagedObjectContext:context];
    
    abstract.title = [json objectForKey:@"title"];
    abstract.text = [json objectForKey:@"abstract"];
    abstract.acknoledgements = [json objectForKey:@"acknowledgements"];
    abstract.references = [json objectForKey:@"refs"];
    abstract.conflictOfInterests = [json objectForKey:@"coi"];
    
    return abstract;
}

@end
