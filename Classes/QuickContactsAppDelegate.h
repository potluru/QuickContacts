/*
     File: QuickContactsAppDelegate.h
 Abstract: The application delegate class used for installing our navigation controller.
  Version: 1.1
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/
#import <UIKit/UIKit.h>

@interface QuickContactsAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
	UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;	

@end

