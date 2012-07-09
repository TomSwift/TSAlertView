//
//  TSAVDemoViewController.m
//  TSAVDemo
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//

#import "TSAVDemoViewController.h"
#import "TSAlertView.h"

@implementation TSAVDemoViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void) onAddMore:(id)sender
{
}

- (void) onShow:(id)sender
{
	[_messageTextView resignFirstResponder];
	[_titleTextField resignFirstResponder];
	[_widthTextField resignFirstResponder];
	[_maxHeightTextField resignFirstResponder];

	TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
	av.title = _titleTextField.text;
	av.message = _messageTextView.text;

	for ( int i = 0 ; i < [_buttonCountTextField.text intValue] ; i++ )
	{
		[av addButtonWithTitle: [NSString stringWithFormat: @"Button %d", i]];
	}

	av.style = _hasInputFieldSwitch.on ? TSAlertViewStyleInput : TSAlertViewStyleNormal;
	av.buttonLayout = _stackedSwitch.on ? TSAlertViewButtonLayoutStacked : TSAlertViewButtonLayoutNormal;
	av.usesMessageTextView = _usesTextViewSwitch.on;

	av.width = [_widthTextField.text floatValue];
	av.maxHeight = [_maxHeightTextField.text floatValue];

	[av show];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
