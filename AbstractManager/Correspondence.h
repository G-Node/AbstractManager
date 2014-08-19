//
//  Correspondence.h
//  AbstractManager
//
//  Created by Christian Kellner on 18/08/14.
//  Copyright (c) 2014 G-Node. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Abstract, Author;

@interface Correspondence : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) Abstract *forAbstract;
@property (nonatomic, retain) Author *ofAuthor;

@end
