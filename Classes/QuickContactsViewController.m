/*
     File: QuickContactsViewController.m
 Abstract: Demonstrates how to use ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate, 
           ABNewPersonViewControllerDelegate, and ABUnknownPersonViewControllerDelegate. Shows how to browse a 
           list of Address Book contacts, display and edit a contact record, create a new contact record, and 
           update a partial contact record.
 
  Version: 1.1
 
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/
#import "QuickContactsViewController.h"
#import "JSONKit.h"

enum TableRowSelected 
{
	kUIDisplayPickerRow = 0,
	kUICreateNewContactRow,
	kUIDisplayContactRow,
	kUIEditUnknownContactRow
};


// Height for the Edit Unknown Contact row
#define kUIEditUnknownContactRowHeight 81.0

@implementation QuickContactsViewController
@synthesize menuArray;

#pragma mark Load views
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	// Load data from the plist file
	NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Menu" ofType:@"plist"];
	self.menuArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
}


#pragma mark Unload views
- (void)viewDidUnload 
{
	self.menuArray = nil;
}


#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [menuArray count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (aCell == nil)
	{
		// Make the Display Picker and Create New Contact rows look like buttons
		if (indexPath.section < 3)
		{
			aCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			aCell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		else
		{
			aCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			aCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			aCell.detailTextLabel.numberOfLines = 0;
			// Display descriptions for the Edit Unknown Contact and Display and Edit Contact rows 
			aCell.detailTextLabel.text = [[menuArray objectAtIndex:indexPath.section] valueForKey:@"description"];
		}
	}
	
	aCell.textLabel.text = [[menuArray objectAtIndex:indexPath.section] valueForKey:@"title"];
	
	return aCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.section)
	{
		case kUIDisplayPickerRow:
			[self showPeoplePickerController];
			break;
		case kUICreateNewContactRow:
			[self showNewPersonViewController];
			break;
		case kUIDisplayContactRow:
			[self showPersonViewController];
			break;
		default:
			[self showPeoplePickerController];
			break;
	}	
}


#pragma mark TableViewDelegate method
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Change the height if Edit Unknown Contact is the row selected
	return (indexPath.section==kUIEditUnknownContactRow) ? kUIEditUnknownContactRowHeight : tableView.rowHeight;	
}


#pragma mark Show all contacts
// Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
// The application only shows the phone, email, and birthdate information of the selected contact.
-(void)showPeoplePickerController
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
	// Display only a person's phone, email, and birthdate
	NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], 
							    [NSNumber numberWithInt:kABPersonEmailProperty],
							    [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
    
	picker.displayedProperties = displayedItems;

    // Allow users to edit the person’s information
    picker.editing = YES;
    
    [[picker navigationBar] setBarStyle:UIBarStyleBlack];
    
	// Show the picker 
	[self presentModalViewController:picker animated:YES];
    [picker release];	
}

-(IBAction)addPerson:(id)sender{
    ABNewPersonViewController *view = [[ABNewPersonViewController alloc] init];
    view.newPersonViewDelegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:view];
    [self presentModalViewController:nc animated:YES];
}

#pragma mark Display and edit a person
// Called when users tap "Display and Edit Contact" in the application. Searches for a contact named "Appleseed" in 
// in the address book. Displays and allows editing of all information associated with that contact if
// the search is successful. Shows an alert, otherwise.
-(void)showPersonViewController
{
    
    NSString* searchURL = @"http://192.168.0.119:8080/resty/service/fetchAllContacts";
	
	NSError* error = nil;
	NSURLResponse* response = nil;
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] init] autorelease];
	
	NSURL* URL = [NSURL URLWithString:searchURL];
	[request setURL:URL];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setTimeoutInterval:30];
	
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		NSLog(@"Error performing request %@", searchURL);
	}
    
	NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	//NSLog(@"We received: %@", jsonString);
    
    NSDictionary *results = [jsonString objectFromJSONString];
	
	NSArray *movieArray = [results objectForKey:@"uploaded"];
    
    if ([movieArray count] > 0)
    {
        
        ABAddressBookRef addressBook = ABAddressBookCreate();
        
        for (NSDictionary *movie in movieArray)
        {
            ABRecordRef person = ABPersonCreate();
            CFErrorRef  anError = NULL;
            
            NSString *firstName = [movie objectForKey:@"firstName"];
            NSString *email = [movie objectForKey:@"email"];
            
            ABRecordSetValue(person,kABPersonFirstNameProperty,(CFTypeRef)firstName,&anError);
            
            ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABPersonEmailProperty);
            
            bool didAddEmail = ABMultiValueAddValueAndLabel(emailMultiValue, email, kABOtherLabel, NULL);
            
            if (didAddEmail == FALSE) {
                NSLog(@"Error populating Email field corresonding to: %@ ", email);
            }
            
            ABRecordSetValue(person,kABPersonEmailProperty,emailMultiValue,nil);
            
            NSLog(@"First Name found: %@", firstName);
            ABAddressBookAddRecord(addressBook, person, &anError);
            ABAddressBookSave(addressBook, &anError);
            [person release];
        }
        
        CFRelease(addressBook);
    }
    
    
}


#pragma mark Create a new person
// Called when users tap "Create New Contact" in the application. Allows users to create a new contact.
-(void)showNewPersonViewController
{
	ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
	picker.newPersonViewDelegate = self;
	
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
	[self presentModalViewController:navigation animated:YES];
	   
	[picker release];
	[navigation release];

/**
    
    NSString* searchURL = @"http://192.168.0.119:8080/resty/service/fetchAllContacts";
	
	NSError* error = nil;
	NSURLResponse* response = nil;
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] init] autorelease];
	
	NSURL* URL = [NSURL URLWithString:searchURL];
	[request setURL:URL];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setTimeoutInterval:30];
	
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		NSLog(@"Error performing request %@", searchURL);
	}
    
	NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	//NSLog(@"We received: %@", jsonString);
    
    NSDictionary *results = [jsonString objectFromJSONString];
	
	NSArray *movieArray = [results objectForKey:@"uploaded"];
    
    if ([movieArray count] > 0)
    {

        ABAddressBookRef addressBook = ABAddressBookCreate();

        for (NSDictionary *movie in movieArray)
        {
            ABRecordRef person = ABPersonCreate();
            CFErrorRef  anError = NULL;
            
            NSString *firstName = [movie objectForKey:@"firstName"];
            NSString *email = [movie objectForKey:@"email"];
            
            ABRecordSetValue(person,kABPersonFirstNameProperty,(CFTypeRef)firstName,&anError);
            
            ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABPersonEmailProperty);
            
            bool didAddEmail = ABMultiValueAddValueAndLabel(emailMultiValue, email, kABOtherLabel, NULL);
            
            if (didAddEmail == FALSE) {
                NSLog(@"Error populating Email field corresonding to: %@ ", email);
            }
            
            ABRecordSetValue(person,kABPersonEmailProperty,emailMultiValue,nil);
            
            NSLog(@"First Name found: %@", firstName);
            ABAddressBookAddRecord(addressBook, person, &anError);
            ABAddressBookSave(addressBook, &anError);
            [person release];
        }
    
        CFRelease(addressBook);
    }
    */
    
}

#pragma mark ABPeoplePickerNavigationControllerDelegate methods
// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{

    //Update Portal
    
    [peoplePicker dismissModalViewControllerAnimated:NO];
    
    ABAddressBookRef addressBook = ABAddressBookCreate(); // this will open the AddressBook of the iPhone
    CFErrorRef error             = NULL;
    
    //peoplePicker.editing = YES;
    
    ABPersonViewController *personController = [[ABPersonViewController alloc] init];
    
    personController.addressBook                       = addressBook; // this passes the reference of the Address Book
    personController.displayedPerson                   = person; // this sets the person reference
    personController.allowsEditing                     = YES; // this allows the user to edit the details
    personController.personViewDelegate                = self;
    personController.navigationItem.rightBarButtonItem = [self editButtonItem]; // this will add the inbuilt Edit button to the view
    
    /**
     * You may need below
     */
//    ABRecordSetValue(person, kABPersonJobTitleProperty, (CFStringRef)empObj.jobTitle, &error);
//    ABAddressBookSave(addressBook, &error);
    
    CFRelease(addressBook);
    
    personController.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonJobTitleProperty]];
    
    // this displays the contact with the details and presents with an Edit button
    [[self navigationController] pushViewController:personController animated:YES];
    
    [personController release];
    
    return YES;

}


// Does not allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return YES;
}


// Dismisses the people picker and shows the application when users tap Cancel. 
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person 
					property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return NO;
}


#pragma mark ABNewPersonViewControllerDelegate methods
// Dismisses the new-person view controller. 
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark ABUnknownPersonViewControllerDelegate methods
// Dismisses the picker when users are done creating a contact or adding the displayed person properties to an existing contact. 
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
}


// Does not allow users to perform default actions such as emailing a contact, when they select a contact property.
- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person 
						   property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}


#pragma mark Memory management
- (void)dealloc 
{
	[menuArray release];
    [super dealloc];
}

@end
