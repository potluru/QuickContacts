/*
     File: QuickContactsAppDelegate.m
 Abstract: The application delegate class used for installing our navigation controller.
  Version: 1.1
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */
#import "QuickContactsAppDelegate.h"

@implementation QuickContactsAppDelegate
@synthesize window;
@synthesize navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
//    [window addSubview:navigationController.view];
     [self.window setRootViewController:navigationController];
	// Override point for customization after application launch
    [window makeKeyAndVisible];
}


- (void)dealloc
{
	[navigationController release];
    [window release];
    [super dealloc];
}

@end
