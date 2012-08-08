//
//  AppDelegate.m
//  AbstractManager
//
// Copyright (c) 2012 Christian Kellner <kellner@bio.lmu.de>.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "AppDelegate.h"

#import "Abstract.h"
#import "Abstract+Create.h"
#import "Abstract+HTML.h"
#import "Author.h"
#import "Author+Create.h"
#import "Affiliation.h"
#import "Organization+Create.h"

#import <WebKit/WebKit.h>


@interface AppDelegate ()  <NSTableViewDataSource, NSTableViewDelegate>
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak) IBOutlet NSTableView *abstractList;
@property (weak) IBOutlet WebView *abstractView;


@end

@implementation AppDelegate
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"org.g-node.DatabaseFiller"];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Abstracts" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![[properties objectForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"G-Node" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Abstracts.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"G-Node" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

# pragma mark - NSWindowDelegate
// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self loadDataFromStore];
    self.abstractList.dataSource = self;
    self.abstractList.delegate = self;
}

#pragma mark - menu

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


- (void) importAbstracts:(NSArray *)abstracts
{
    NSManagedObjectContext *context = self.managedObjectContext;
    for (NSDictionary *absDict in abstracts) {
        
        NSLog(@"%@\n", [absDict objectForKey:@"title"]);
        Abstract *abstract = [Abstract abstractForJSON:absDict inManagedObjectContext:context];
        
        // Author
        NSArray *authors = [absDict objectForKey:@"authors"];
        
        NSMutableOrderedSet *authorSet = [[NSMutableOrderedSet alloc] init];
        for (NSDictionary *authorDict in authors) {
            NSString *name = [authorDict objectForKey:@"name"];
            Author *author = [Author findOrCreateforName:name inManagedContext:context];
            [authorSet addObject:author];
        }
        
        if (authorSet.count > 0)
            abstract.authors = authorSet;
        
        // Affiliations
        NSMutableOrderedSet *affiliations = [[NSMutableOrderedSet alloc] init];
        NSDictionary *afDict = [absDict objectForKey:@"affiliations"];
        NSUInteger index = 1;
        for (NSString *key in afDict) {
            NSString *value = [afDict objectForKey:key];
            Organization *orga = [Organization findOrCreateForString:value inManagedContext:context];
            
            Affiliation *affiliation = [NSEntityDescription insertNewObjectForEntityForName:@"Affiliation" inManagedObjectContext:context];
            
            affiliation.toOrganization = orga;
            
            NSMutableSet *afAuthors = [[NSMutableSet alloc] init];
            for (NSUInteger idxAuthor = 0; idxAuthor < authors.count; idxAuthor++) {
                NSDictionary *authorDict = [authors objectAtIndex:idxAuthor];
                NSArray *afArray = [authorDict objectForKey:@"affiliations"];
                
                for (NSNumber *afNum in afArray) {
                    if ([afNum unsignedIntegerValue] == index) {
                        [afAuthors addObject:[authorSet objectAtIndex:idxAuthor]];
                        break;
                    }
                }
            }
            
            affiliation.ofAuthors = afAuthors;
            
            [affiliations addObject:affiliation];
            index++;
        }
        
        abstract.affiliations = affiliations;
    }
}

- (IBAction)importData:(id)sender
{
    NSOpenPanel* importDialog = [NSOpenPanel openPanel];
    importDialog.canChooseFiles = YES;
    importDialog.canChooseDirectories = NO;
    importDialog.allowsMultipleSelection = NO;
    
    [importDialog beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSData *data = [[NSData alloc] initWithContentsOfURL:importDialog.URL];
            id list = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![list isKindOfClass:[NSArray class]]) {
                NSLog(@"NOT A ARRAY!\n");
                return;
            }
            
            NSArray *abstracts = (NSArray *) list;
            
            [self importAbstracts:abstracts];
            [self loadDataFromStore];
            [self.abstractList reloadData];
        }
    }];   
}

- (void)loadDataFromStore
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Abstract"
                                              inManagedObjectContext:self.managedObjectContext];
    
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    NSLog(@"results.count: %lu\n", results.count);
    self.abstracts = results;
}


#pragma mark - TableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return self.abstracts.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
    NSLog (@"%@\n", aTableColumn.identifier);
    
    Abstract *abstract = (Abstract *) [self.abstracts objectAtIndex:rowIndex];
    
    NSString *text;
    if ([aTableColumn.identifier isEqualToString:@"author"]) {
        Author *author = [abstract.authors objectAtIndex:0];
        text = author.name;
    } else {
        text = abstract.title;
    }
    
    return text;
}

#pragma - TableViewDelegate
- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
    
    if ([notification object] != self.abstractList)
        return;
    
    NSInteger row = [self.abstractList selectedRow];
    
    Abstract *abstract = (Abstract *) [self.abstracts objectAtIndex:row];
    NSString *html = [abstract renderHTML];
    NSURL *base = [NSURL URLWithString:@"http://"];
    [self.abstractView.mainFrame loadHTMLString:html baseURL:base];
    NSLog(@"RowSelected %ld %@", row, html);
}

#pragma - NSOutlineViewDataSource
- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    
}


@end
