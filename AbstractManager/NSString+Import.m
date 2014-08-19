//
//  NSString+Import.m
//  AbstractManager
//
//  Created by Christian Kellner on 18/08/14.
//  Copyright (c) 2014 G-Node. All rights reserved.
//

#import "NSString+Import.h"

@implementation NSString (Import)
+(NSString *)mkStringForJS:(id) val
{
    NSNull *null = [NSNull null];

    if (val == nil || val == null) {
        return nil;
    }

    return [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
