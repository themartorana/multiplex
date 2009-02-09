#import "PreferencesWindowController.h"
#import "PreferencesWindow.h"

static NSString* const TOOLBAR_GENERAL = @"General";
static NSString* const TOOLBAR_APPEARANCE = @"Appearance";
static NSString* const TOOLBAR_ADVANCED = @"Advanced";

@implementation PreferencesWindowController

- (id) initWithApplicationController:(ApplicationController*)applicationController
{
    if (self = [super init]) {
        appController = [applicationController retain];
        
        if (![NSBundle loadNibNamed:@"Preferences" owner:self]) {
            return nil;
        }
    }
    
    return self;
}

- (NSToolbarItem*) toolbar:(NSToolbar*) toolbar itemForItemIdentifier:(NSString*)ident willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        
    if ([ident isEqualToString:TOOLBAR_GENERAL]) {
        [item setLabel:NSLocalizedString(@"General", "Preferences -> toolbar item title")];
        [item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } else if ([ident isEqualToString:TOOLBAR_APPEARANCE]) {
        [item setLabel:NSLocalizedString(@"Appearance", "Preferences -> toolbar item title")];
        [item setImage:[NSImage imageNamed:NSImageNameColorPanel]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } 
    else if ([ident isEqualToString:TOOLBAR_ADVANCED]) {
        [item setLabel:NSLocalizedString(@"Advanced", "Preferences -> toolbar item title")];
        [item setImage:[NSImage imageNamed:NSImageNameAdvanced]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    }
    else {
        item = nil;
    }
    
    return item;
}

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
            TOOLBAR_GENERAL, 
            TOOLBAR_APPEARANCE,
            TOOLBAR_ADVANCED,
            nil
            ];
}

- (NSArray*) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
            TOOLBAR_GENERAL, 
            TOOLBAR_ADVANCED,
            nil
            ];
}

- (void) setPrefView:(id)prefView
{
    NSView* view = generalView;
    if (prefView) {
        NSString* identifier = [prefView itemIdentifier];
        if ([identifier isEqualToString:TOOLBAR_APPEARANCE]) {
            view = appearanceView;
        } else if ([identifier isEqualToString:TOOLBAR_ADVANCED]) { 
            view = advancedView;
        } else {
            view = generalView;
        }
    }
    
    NSWindow* window = [self window];
    if ([window contentView] != view) {
        NSRect windowRect = [window frame];
        float difference = ([view frame].size.height - [[window contentView] frame].size.height) * [window userSpaceScaleFactor];
        windowRect.origin.y -= difference;
        windowRect.size.height += difference;
        
        [view setHidden:YES];
        [window setContentView:view];
        [window setFrame:windowRect display:YES animate:YES];
        [view setHidden:NO];
        
        if (prefView) {
            [window setTitle:[prefView label]];
        } else {
            NSToolbar* toolbar = [window toolbar];
            NSString* itemIdentifier = [toolbar selectedItemIdentifier];
            for (NSToolbarItem* item in [toolbar items]) {
                if ([[item itemIdentifier] isEqualToString:itemIdentifier]) {
                    [window setTitle:[item label]];
                    break;
                }
            }
        }
    }
}

- (void) awakeFromNib
{
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Toolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setSelectedItemIdentifier:TOOLBAR_GENERAL];
    [[self window] setToolbar:toolbar];
    [toolbar release];
    
    [self setPrefView:nil];
}


@end
