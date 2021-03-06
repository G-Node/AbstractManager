//
//  Figure.h
//  AbstractManager
//
//  Created by Christian Kellner on 19/08/14.
//  Copyright (c) 2014 G-Node. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Abstract;

@interface Figure : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Abstract *ofAbstract;

@end
