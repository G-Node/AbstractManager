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
#import "Abstract+XML.h"
#import "Author.h"
#import "Author+Create.h"
#import "Affiliation.h"
#import "Organization+Create.h"

#import <WebKit/WebKit.h>

typedef enum _GroupType {
    GT_UNSORTED = 0,
    GT_I = 1,
    GT_W = 2,
    GT_T = 3,
    GT_F = 4
} GroupType;

@interface AbstractGroup : NSObject
@property (strong, nonatomic) NSMutableOrderedSet  *abstracts;
@property (readonly, nonatomic) NSString *name;
@property (nonatomic) GroupType type;
+ (AbstractGroup *) groupWithType:(GroupType) groupType;

@end

@implementation AbstractGroup
@synthesize abstracts = _abstracts;

+ (AbstractGroup *) groupWithType:(GroupType)groupType
{
    AbstractGroup *group = [[AbstractGroup alloc] init];
    group.type = groupType;
    return group;
}

- (NSString *)name {
    switch (self.type) {
        case GT_UNSORTED:
            return @"Unsorted";
            break;
        case GT_I:
            return @"Invited Talk";
            break;
        case GT_W:
            return @"Wednesday";
            break;
        case GT_T:
            return @"Thursday";
            break;
        case GT_F:
            return @"Friday";
            break;
    }
}
- (NSMutableOrderedSet *)abstracts
{
    if (_abstracts == nil) {
        _abstracts = [[NSMutableOrderedSet alloc] init];
    }
    return _abstracts;
}

@end

#define PT_REORDER @"PasteBoardTypeReorder"

@interface AppDelegate ()  <NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak) IBOutlet NSOutlineView *abstractOutline;

@property (weak) IBOutlet NSTableView *abstractList;
@property (weak) IBOutlet WebView *abstractView;
@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) NSOrderedSet *abstractGroups;
@property (strong, nonatomic) NSString *latexStylesheet;
@property (strong, nonatomic) NSString *htmlStylesheet;
@end

@implementation AppDelegate
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize abstractOutline = _abstractOutline;
@synthesize abstractGroups = _abstractGroups;
@synthesize latexStylesheet = _latexStylesheet;
@synthesize htmlStylesheet = _htmlStylesheet;

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
    NSMutableArray *roots = [NSMutableArray arrayWithCapacity:4];
    [roots addObject:[AbstractGroup groupWithType:GT_I]];
    [roots addObject:[AbstractGroup groupWithType:GT_W]];
    [roots addObject:[AbstractGroup groupWithType:GT_T]];
    [roots addObject:[AbstractGroup groupWithType:GT_F]];
    [roots addObject:[AbstractGroup groupWithType:GT_UNSORTED]];
    
    self.groups = roots;
    
    [self loadDataFromStore];
    
    self.abstractOutline.dataSource = self;
    self.abstractOutline.delegate = self;
    self.abstractList.dataSource = self;
    self.abstractList.delegate = self;
    
    [self.abstractOutline registerForDraggedTypes:[NSArray arrayWithObject:PT_REORDER]];
    [self.abstractOutline setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [self.abstractOutline setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (NSString *) askUserForStylesheetwithHandler:(void (^)(NSInteger result, NSURL *url))handler
{
    NSOpenPanel *chooser = [NSOpenPanel openPanel];
    chooser.title = @"Please select stylesheet";

    NSArray *filetypes = [NSArray arrayWithObjects:@"xsl", @"xslt", nil];
    chooser.allowedFileTypes = filetypes;
    
    chooser.canChooseFiles = YES;
    chooser.canChooseDirectories = NO;
    chooser.allowsMultipleSelection = NO;
    
    __block NSInteger success = 0;
    [chooser beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        handler (result, chooser.URL);
    }];
    
    return success ? chooser.URL.path : nil;
}

- (NSString *) latexStylesheet
{
    if (_latexStylesheet == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _latexStylesheet = [defaults stringForKey:@"latex_stylesheet"];
    }
    
    return _latexStylesheet;
}

- (void) setLatexStylesheet:(NSString *)stylesheet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:stylesheet forKey:@"latex_stylesheet"];
    _latexStylesheet = stylesheet;
}


- (NSString *) htmlStylesheet
{
    if (_htmlStylesheet == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _htmlStylesheet = [defaults stringForKey:@"html_stylesheet"];
    }
    
    return _htmlStylesheet;
}

- (void) setHtmlStylesheet:(NSString *)htmlStylesheet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:htmlStylesheet forKey:@"html_stylesheet"];
    NSLog(@"Setting html stylehseet\n");
    _htmlStylesheet = htmlStylesheet;
}

#pragma mark - menu
- (IBAction)menuSetStylesheet:(id)sender
{
    [self askUserForStylesheetwithHandler:^(NSInteger result, NSURL *url) {
        if (result == NSFileHandlingPanelOKButton) {
            NSLog(@"Setting Tex stylehseet %@\n", url.path);
            self.latexStylesheet = url.path;
        }
    }];
}

- (IBAction)menuSetHTMLStylesheet:(id)sender
{
    [self askUserForStylesheetwithHandler:^(NSInteger result, NSURL *url) {
        if (result == NSFileHandlingPanelOKButton) {
            NSLog(@"Setting HTML stylehseet %@\n", url.path);
            self.htmlStylesheet = url.path;
        }
    }];
}

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
    
    int32_t count = 1;
    for (NSDictionary *absDict in abstracts) {
        
        NSLog(@"%@\n", [absDict objectForKey:@"title"]);
        Abstract *abstract = [Abstract abstractForJSON:absDict withId:count inManagedObjectContext:context];
        
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
        count++;
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
            [self.abstractOutline reloadData];
        }
    }];   
}

- (void)loadDataFromStore
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Abstract"
                                              inManagedObjectContext:self.managedObjectContext];
    
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"aid" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    NSLog(@"results.count: %lu\n", results.count);
    self.abstracts = results;
    
    for (Abstract *abstract in self.abstracts) {
        int32_t aid = abstract.aid;
        NSUInteger ngroups = self.groups.count;
        NSUInteger groupIndex = ((aid & (0xFFFF << 16)) + ngroups-1) % ngroups;
        NSUInteger abstractIndex = (aid & 0xFFFF) - 1;
        
        AbstractGroup *group = [self.groups objectAtIndex:groupIndex];
        [group.abstracts insertObject:abstract atIndex:abstractIndex];
    }
}


- (void) saveAbstractsToLocation:(NSString *)path
{
    NSMutableArray *all = [[NSMutableArray alloc] initWithCapacity:self.abstracts.count];
    for (Abstract *abstract in self.abstracts) {
        NSDictionary *dict = [abstract json];
        [all addObject:dict];
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:all options:NSJSONWritingPrettyPrinted error:nil];
    BOOL success = [data writeToFile:path atomically:YES];
    NSLog(@"Written data: %d\n", success);
}


- (NSXMLDocument *) exportToXML
{
    NSXMLElement *root =
    (NSXMLElement *)[NSXMLNode elementWithName:@"abstracts"];
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithRootElement:root];
    [doc setVersion:@"1.0"];
    [doc setCharacterEncoding:@"UTF-8"];
    
    for (Abstract *abstract in self.abstracts) {
        NSXMLNode *node = [abstract xml];
        [root addChild:node];
    }
    
    return doc;
}

- (NSXMLDocument *) exportXMLtoFile:(NSString *)path
{
    NSXMLDocument *doc = [self exportToXML];
    
    NSData *xmlData = [doc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToFile:path atomically:YES]) {
        NSBeep();
        NSLog(@"Could not write document out...");
    }

    return doc;
}

- (IBAction)exportAbstracts:(id)sender
{
    NSSavePanel *chooser = [NSSavePanel savePanel];
    
    NSArray *fileTypes = [NSArray arrayWithObjects:@"json", @"xml", @"tex", @"htm", @"html", nil];
    chooser.allowedFileTypes = fileTypes;
    chooser.allowsOtherFileTypes = NO;
    [chooser beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSLog(@"%@", chooser.URL.path);
            NSString *ext = [chooser.URL.path pathExtension];
            if ([ext isEqualToString:@"json"]) {
                [self saveAbstractsToLocation:chooser.URL.path];
            } else if ([ext isEqualToString:@"xml"]) {
                [self exportXMLtoFile:chooser.URL.path];
            } else if ([ext isEqualToString:@"tex"]) {
                NSXMLDocument *doc = [self exportToXML];
                
                NSString *stylesheet = self.latexStylesheet;
                if (!stylesheet) {
                    NSLog(@"No stylesheet given\n");
                    return;
                }
                NSError *error = nil;
                NSURL *url = [NSURL URLWithString:stylesheet];
                NSData *data = [doc objectByApplyingXSLTAtURL:url arguments:nil error:&error];
                
                if (data == nil) {
                    NSLog(@"Could not transform document!\n");
                    NSBeep();
                    return;
                }
                
                if (![data writeToFile:chooser.URL.path atomically:YES]) {
                    NSBeep();
                    NSLog(@"Could not write document out...");
                }
            }  else if ([ext isEqualToString:@"html"] || [ext isEqualToString:@"htm"]) {
                NSXMLDocument *doc = [self exportToXML];
                NSString *stylesheet = self.htmlStylesheet;
                if (!stylesheet) {
                    NSLog(@"No stylesheet given\n");
                    return;
                }
                
                NSURL *url = [NSURL fileURLWithPath:stylesheet];
                NSXMLDocument  *html = (NSXMLDocument *)[doc objectByApplyingXSLTAtURL:url arguments:nil error:nil];
                
                if (html == nil) {
                    NSLog(@"Could not transform to HTML\n");
                }
                
                NSData *data = [html XMLDataWithOptions:NSXMLNodePrettyPrint];
                if (![data writeToFile:chooser.URL.path atomically:YES]) {
                    NSBeep();
                    NSLog(@"Could not write document out...");
                }
            }
        }
    }];
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

    NSInteger nchildren = 0;
    if (item == nil)
        nchildren = self.groups.count;
    else if ([item isKindOfClass:[AbstractGroup class]]) {
        AbstractGroup *group = item;
        nchildren = group.abstracts.count;
    }
    
    NSLog(@"- numberofChildren: %ld", nchildren);
    return nchildren;
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [self.groups objectAtIndex:index];
    } else if ([item isKindOfClass:[AbstractGroup class]]) {
        AbstractGroup *group = item;
        return [group.abstracts objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[AbstractGroup class]]) {
        return YES;
    }
    
    return NO;
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *text = nil;
    if ([item isKindOfClass:[AbstractGroup class]]) {
        AbstractGroup *group = item;

        if ([tableColumn.identifier isEqualToString:@"author"]) {
            text = group.name;
        } else {
            text = [NSString stringWithFormat:@"%ld", group.abstracts.count];
        }
    } else if ([item isKindOfClass:[Abstract class]]) {
        Abstract *abstract = item;
        if ([tableColumn.identifier isEqualToString:@"author"]) {
            Author *author = [abstract.authors objectAtIndex:0];
            text = author.name;
        } else {
            text = abstract.title;
        }
    }
    return text;
}


- (void) outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [self.abstractOutline selectedRow];
    id item = [self.abstractOutline itemAtRow:row];
    
    if ([item isKindOfClass:[Abstract class]]) {
        Abstract *abstract = item;
        NSString *html = [abstract renderHTML];
        NSURL *base = [NSURL URLWithString:@"http://"];
        [self.abstractView.mainFrame loadHTMLString:html baseURL:base];
    }
    
}

#pragma - Drag & Drop

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView
                pasteboardWriterForItem:(id)item
{
    if ([item isKindOfClass:[Abstract class]]) {
        Abstract *abstract = item;
        return abstract.title;
    }
    return nil;
}

- (void) outlineView:(NSOutlineView *)outlineView
     draggingSession:(NSDraggingSession *)session
    willBeginAtPoint:(NSPoint)screenPoint
            forItems:(NSArray *)draggedItems
{
    int32_t aid = [[draggedItems lastObject] aid];
    NSData *data = [NSData dataWithBytes:&aid length:sizeof(aid)];
    [session.draggingPasteboard setData:data forType:PT_REORDER];
}

- (void) outlineView:(NSOutlineView *)outlineView
     draggingSession:(NSDraggingSession *)session
        endedAtPoint:(NSPoint)screenPoint
           operation:(NSDragOperation)operation
{
    NSLog(@"Drag ended\n");
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
                  validateDrop:(id <NSDraggingInfo>)info
                  proposedItem:(id)item
            proposedChildIndex:(NSInteger)childIndex
{
    NSDragOperation result = NSDragOperationNone;
    
    if ([item isKindOfClass:[AbstractGroup class]]) {
        result = NSDragOperationGeneric;
    }
    
    return result;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView
          acceptDrop:(id <NSDraggingInfo>)info
                item:(id)item
          childIndex:(NSInteger)childIndex
{
    if (item == nil)
        return NO;
    

    NSPasteboard *board = [info draggingPasteboard];
    NSData *data = [board dataForType:PT_REORDER];
    int32_t aid;
    [data getBytes:&aid length:sizeof(aid)];
  
    NSLog(@"%@ %ld", item, childIndex);
    NSUInteger ngroups = self.groups.count;
    NSUInteger groupIndex = ((aid & (0xFFFF << 16)) + ngroups-1) % ngroups;
    NSUInteger abstractIndex = (aid & 0xFFFF) - 1; // abstract ids start at 1
      NSLog(@"aid: %d [%lu %lu]\n", aid, groupIndex, abstractIndex);

    AbstractGroup *sourceGroup = [self.groups objectAtIndex:groupIndex];
    Abstract *abstract = [sourceGroup.abstracts objectAtIndex:abstractIndex];
        NSLog(@"sourceGroupIdx: %lu, %@\n", groupIndex, sourceGroup.name);
    [outlineView beginUpdates];
    
    [sourceGroup.abstracts removeObjectAtIndex:abstractIndex];
    for (NSUInteger i = abstractIndex; i < sourceGroup.abstracts.count; i++) {
        Abstract *A = [sourceGroup.abstracts objectAtIndex:i];
        int32_t newAid = (sourceGroup.type << 16) | (int32_t) (i + 1);
        NSLog(@"S: new aid: %d [%lu]\n", newAid, i);
        A.aid = newAid;
    }
    
    [outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:abstractIndex]
                             inParent:sourceGroup
                        withAnimation:NSTableViewAnimationEffectNone];
    
    AbstractGroup *destGroup = item;
    
    if (childIndex == -1)
        childIndex = destGroup.abstracts.count;
    
    
    [destGroup.abstracts insertObject:abstract atIndex:childIndex];
    for (NSUInteger i = childIndex; i < destGroup.abstracts.count; i++) {
        int32_t newAid = (destGroup.type << 16) | ((int32_t) i + 1);
        NSLog(@"new aid: %d [%lu]\n", newAid, i);
        Abstract *A = [destGroup.abstracts objectAtIndex:i];
        A.aid = newAid;

    }
    
    [outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:childIndex]
                             inParent:item
                        withAnimation:NSTableViewAnimationEffectGap];
    
    [outlineView endUpdates];
    
    NSLog(@"acceptDrop\n");
    return NO;
}

@end
