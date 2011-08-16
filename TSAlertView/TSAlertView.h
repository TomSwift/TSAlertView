//
//  TSAlertView.h
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum 
{
    TSAlertViewButtonLayoutNormal,
    TSAlertViewButtonLayoutStacked
    
} TSAlertViewButtonLayout;

typedef enum
{
    TSAlertViewStyleNormal,
    TSAlertViewStyleInput,
    
} TSAlertViewStyle;

@class TSAlertViewController;
@class TSAlertView;

@protocol TSAlertViewDelegate <NSObject>

@optional
// Called when a button is clicked. The view will be automatically dismissed
// after this call returns
- (void)    alertView:(TSAlertView *)alertView
 clickedButtonAtIndex:(NSInteger)buttonIndex;

// Called when we cancel a view (eg. the user clicks the Home button). This is
// not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(TSAlertView *)alertView;

// Before animation and showing view
- (void)willPresentAlertView:(TSAlertView *)alertView;
// After animation
- (void)didPresentAlertView:(TSAlertView *)alertView;

// Before animation and hiding view
- (void)            alertView:(TSAlertView *)alertView
   willDismissWithButtonIndex:(NSInteger)buttonIndex;
// After animation 
- (void)        alertView:(TSAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end

@interface TSAlertView: UIView
{
    id<TSAlertViewDelegate> _delegate;
    UIImage *_backgroundImage;
    UILabel *_titleLabel;
    UILabel *_messageLabel;
    UITextView *_messageTextView;
    UIImageView *_messageTextViewMaskImageView;
    NSMutableArray *_buttons;
    NSInteger _cancelButtonIndex;
    TSAlertViewButtonLayout _buttonLayout;
    NSInteger _firstOtherButtonIndex;
    CGFloat _width;
    CGFloat _maxHeight;
    BOOL _usesMessageTextView;
    TSAlertViewStyle _style;
    // TSAlertView (TSCustomizableAlertView)
    NSMutableArray *_textFields;
}

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, assign) id<TSAlertViewDelegate> delegate;
@property(nonatomic, assign) NSInteger cancelButtonIndex;
@property(nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property(nonatomic, readonly) NSInteger numberOfButtons;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;

@property(nonatomic, assign) TSAlertViewButtonLayout buttonLayout;
@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat maxHeight;
@property(nonatomic, assign) BOOL usesMessageTextView;
@property(nonatomic, retain) UIImage *backgroundImage;
@property(nonatomic, assign) TSAlertViewStyle style;
@property(nonatomic, readonly) UITextField *inputTextField;

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...;
- (NSInteger)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex
                             animated:(BOOL)animated;
- (void)show;
@end

@interface TSAlertView (TSCustomizableAlertView)

// Returns the number of text fields added to the current instance
@property (nonatomic, readonly) NSInteger numberOfTextFields;
// Returns the first text field, identical to the message textFieldForIndex:
// with 0 as it argument, with the exception that firstTextField will return nil
// if there aren't any text fields, whereas textFieldForIndex: will throw an
// exception
@property (nonatomic, readonly) UITextField *firstTextField;

// Allows you to add a UITextField directly, without having TSAlertView to
// create it for you
- (void)addTextField:(UITextField *)textField;
// Creates and adds a UITextField, setting the placeholder value to the label
// parameter
- (UITextField *)addTextFieldWithLabel:(NSString *)label;
// Creates and adds a UITextField, setting the placeholder value to the label
// parameter, and the text value to the value parameter
- (UITextField *)addTextFieldWithLabel:(NSString *)label
                                 value:(NSString *)value;
// Returns the UITextField instance at the specified index. Note: this method
- (UITextField *)textFieldAtIndex:(NSInteger)index;
@end
