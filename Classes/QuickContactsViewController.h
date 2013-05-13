/*
     File: QuickContactsViewController.h
 Abstract: Definitions for the QuickContactsViewController class.
  Version: 1.1
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface QuickContactsViewController : UITableViewController < ABPeoplePickerNavigationControllerDelegate,
																 ABPersonViewControllerDelegate,
															     ABNewPersonViewControllerDelegate,
												                 ABUnknownPersonViewControllerDelegate>
{
	NSMutableArray *menuArray;
}
@property (nonatomic, retain) NSMutableArray *menuArray;

-(void)showPeoplePickerController;
-(void)showPersonViewController;
-(void)showNewPersonViewController;
-(void)showUnknownPersonViewController;

@end
