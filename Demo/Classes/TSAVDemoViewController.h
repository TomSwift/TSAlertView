//
//  TSAVDemoViewController.h
//  TSAVDemo
//
//  Created by Nick Hodapp on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TSAVDemoViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
	IBOutlet UITextField*		_titleTextField;
	
	IBOutlet UITextView*		_messageTextView;
	
	IBOutlet UITextField*		_widthTextField;
	
	IBOutlet UITextField*		_maxHeightTextField;

	IBOutlet UITextField*		_buttonCountTextField;


	IBOutlet UISwitch*			_stackedSwitch;

	IBOutlet UISwitch*			_usesTextViewSwitch;
	
	IBOutlet UISwitch*			_hasInputFieldSwitch;
}

- (void) onAddMore: (id) sender;

- (void) onShow: (id) sender;

@end
