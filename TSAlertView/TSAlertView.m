//
//  TSAlertView.m
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "TSAlertView.h"

const CGFloat kTSAlertView_LeftMargin = 10.;
const CGFloat kTSAlertView_TopMargin = 16.;
const CGFloat kTSAlertView_BottomMargin = 15.;
const CGFloat kTSAlertView_RowMargin = 5.;
const CGFloat kTSAlertView_ColumnMargin = 10.;

@interface NSString (TSString)

- (BOOL)isBlank;
@end

@implementation NSString (TSString)

- (BOOL)isBlank
{
    static NSCharacterSet *whitespaceCharSet = nil;

    if (whitespaceCharSet == nil)
        whitespaceCharSet =
                [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];

    return [@"" isEqualToString:[self stringByTrimmingCharactersInSet:
            whitespaceCharSet]];
}
@end

@interface TSAlertOverlayWindow : UIWindow
{
    UIWindow *_oldKeyWindow;
    UIViewController *_rootController;
}
@property (nonatomic, retain) UIWindow *oldKeyWindow;
@property (nonatomic, retain) UIViewController *rootController;
@end

@implementation  TSAlertOverlayWindow

#pragma mark -
#pragma mark NSObject

- (void)dealloc
{
    [_oldKeyWindow release];
    _rootController = nil;
    NSLog(@"TSAlertView: TSAlertOverlayWindow dealloc");
    [super dealloc];
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect
{
    // render the radial gradient behind the alertview
    CGFloat width = [self bounds].size.width;
    CGFloat height = [self bounds].size.height;
    CGFloat locations[3] = {.0, .5, 1.};
    CGFloat components[12] = {
        1., 1., 1., .5,
        .0, .0, .0, .5,
        .0, .0, .0, .7};
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef backgroundGradient = CGGradientCreateWithColorComponents(
            colorspace, components, locations, 3);
    CGColorSpaceRelease(colorspace);
    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), 
            backgroundGradient, 
            CGPointMake(width / 2., height / 2.), .0,
            CGPointMake(width / 2., height / 2.), width,
            .0);
    CGGradientRelease(backgroundGradient);
}

#pragma mark -
#pragma mark UIWindow

- (void)makeKeyAndVisible
{
    [self setOldKeyWindow:[[UIApplication sharedApplication] keyWindow]];
    [self setWindowLevel:UIWindowLevelAlert];
    [super makeKeyAndVisible];
}

- (void)resignKeyWindow
{
    [super resignKeyWindow];
    [_oldKeyWindow makeKeyWindow];
}

#pragma mark -
#pragma mark TSAlertOverlayWindow

@synthesize oldKeyWindow = _oldKeyWindow,
        rootController = _rootController;

- (void)setRootController:(UIViewController *)controller
{
    if (_rootController != controller) {
        [[_rootController view] removeFromSuperview];
        [_rootController autorelease];
        _rootController = [controller retain];
        [self addSubview:[controller view]];
    }
}
@end

@interface TSAlertViewController: UIViewController
@end

@implementation TSAlertViewController

#pragma mark -
#pragma mark NSObject

- (void)dealloc
{
    NSLog(@"TSAlertView: TSAlertViewController dealloc");
    [super dealloc];
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    TSAlertView* av = [self.view.subviews lastObject];

    if (!av || ![av isKindOfClass:[TSAlertView class]])
        return;
    // resize the alertview if it wants to make use of any extra space
    // (or needs to contract)
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
     [av sizeToFit];
     av.center = CGPointMake(CGRectGetMidX(self.view.bounds),
            CGRectGetMidY(self.view.bounds));
     av.frame = CGRectIntegral(av.frame);
    [UIView commitAnimations];
}
@end

@interface UITextField (TSSize)

- (CGSize)sizeForAlertView:(TSAlertView *)alertView;
@end

@implementation UITextField (TSSize)

- (CGSize)sizeForAlertView:(TSAlertView *)alertView
{
    if ([alertView style] == TSAlertViewStyleNormal)
        return CGSizeZero;
    
    CGFloat maxWidth = [alertView width] - (kTSAlertView_LeftMargin * 2.);
    CGSize size = [self sizeThatFits:CGSizeZero];

    return CGSizeMake(maxWidth, size.height);
}
@end

@interface TSAlertView (Private)

@property (nonatomic, readonly) NSMutableArray *buttons;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *messageLabel;
@property (nonatomic, readonly) UITextView *messageTextView;
@property (nonatomic, readonly) UIImageView *messageTextViewMaskView;
@property (nonatomic, readonly) NSMutableArray *textFields;
- (void)TSAlertView_commonInit;
- (void)releaseWindow:(int)buttonIndex;
- (void)pulse;
- (void)pulseDidStop1:(NSString *)animationID
            finished:(NSNumber *)finished
             context:(void *)context;
- (void)pulseDidStop2:(NSString *)animationID
            finished:(NSNumber *)finished
             context:(void *)context;
- (CGSize)titleLabelSize;
- (CGSize)messageLabelSize;
- (CGSize)inputTextFieldSize;
- (CGSize)buttonsAreaSize_Stacked;
- (CGSize)buttonsAreaSize_SideBySide;
- (CGSize)recalcSizeAndLayout:(BOOL)layout;
- (void)onKeyboardWillShow:(NSNotification *)note;
- (void)onKeyboardWillHide:(NSNotification *)note;
- (void)onButtonPress:(id)sender;
- (void)setTextFieldProperties:(UITextField **)textField;
@end

@implementation TSAlertView

#pragma mark -
#pragma mark NSObject

- (id)init 
{
    if ((self = [super init]) != nil)
        [self TSAlertView_commonInit];
    return self;
}

- (void)dealloc 
{
    _delegate = nil;
    [_backgroundImage release];
    [_buttons release];
    [_titleLabel release];
    [_messageLabel release];
    [_messageTextView release];
    [_messageTextViewMaskImageView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"TSAlertView: TSAlertOverlayWindow dealloc");
    [super dealloc];
}

#pragma mark -
#pragma mark UIView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]) != nil) {
        [self TSAlertView_commonInit];
        if (!CGRectIsEmpty(frame))
        {
            _width = frame.size.width;
            _maxHeight = frame.size.height;
        }
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)unused 
{
    CGSize size = [self recalcSizeAndLayout:NO];

    return size;
}

- (void)layoutSubviews
{
    [self recalcSizeAndLayout:YES];
}

- (void)drawRect:(CGRect)rect
{
    [[self backgroundImage] drawInRect: rect];
}

#pragma mark -
#pragma mark TSAlertView (Private)

- (NSMutableArray *)buttons
{
    if (_buttons == nil)
        _buttons = [[NSMutableArray arrayWithCapacity:4] retain];
    return _buttons;
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        [_titleLabel setFont:[UIFont boldSystemFontOfSize:18.]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setTextColor:[UIColor whiteColor]];
        [_titleLabel setTextAlignment:UITextAlignmentCenter];
        [_titleLabel setLineBreakMode:UILineBreakModeWordWrap];
        [_titleLabel setNumberOfLines:0];
    }
    return _titleLabel;
}

- (UILabel *)messageLabel
{
    if ( _messageLabel == nil ) {
        _messageLabel = [[UILabel alloc] init];
        [_messageLabel setFont:[UIFont systemFontOfSize:16.]];
        [_messageLabel setBackgroundColor:[UIColor clearColor]];
        [_messageLabel setTextColor:[UIColor whiteColor]];
        [_messageLabel setTextAlignment:UITextAlignmentCenter];
        [_messageLabel setLineBreakMode:UILineBreakModeWordWrap];
        [_messageLabel setNumberOfLines:0];
    }
    return _messageLabel;
}

- (UITextView *)messageTextView
{
    if (_messageTextView == nil) {
        _messageTextView = [[UITextView alloc] init];
        [_messageTextView setEditable:NO];
        [_messageTextView setFont:[UIFont systemFontOfSize:16.]];
        [_messageTextView setBackgroundColor:[UIColor whiteColor]];
        [_messageTextView setTextColor:[UIColor darkTextColor]];
        [_messageTextView setTextAlignment:UITextAlignmentLeft];
        [_messageTextView setBounces:YES];
        [_messageTextView setAlwaysBounceVertical:YES];
        [[_messageTextView layer] setCornerRadius:5.];
    }
    return _messageTextView;
}

- (UIImageView *)messageTextViewMaskView
{
    if (_messageTextViewMaskImageView == nil) {
        UIImage* shadowImage =
                [[UIImage imageNamed:@"TSAlertViewMessageListViewShadow.png"]
                    stretchableImageWithLeftCapWidth:6 topCapHeight:7];
        
        _messageTextViewMaskImageView =
                [[UIImageView alloc] initWithImage:shadowImage];
        [_messageTextViewMaskImageView setUserInteractionEnabled:NO];

        CALayer *layer = [_messageTextViewMaskImageView layer];

        [layer setMasksToBounds:YES];
        [layer setCornerRadius:6.];
    }
    return _messageTextViewMaskImageView;
}

- (NSMutableArray *)textFields
{
    if (_textFields == nil)
        [self inputTextField];
    return _textFields;
}

- (void)TSAlertView_commonInit
{
    [self setBackgroundColor:[UIColor clearColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin]; 
    // defaults:
    _style = TSAlertViewStyleNormal;
    [self setWidth:.0]; // set to default
    [self setMaxHeight:.0]; // set to default
    _buttonLayout = TSAlertViewButtonLayoutNormal;
    _cancelButtonIndex = -1;
    _firstOtherButtonIndex = -1;
}

- (void)releaseWindow:(int)buttonIndex
{
    if ([[self delegate] respondsToSelector:
            @selector(alertView:didDismissWithButtonIndex:)])
        [[self delegate] alertView:self didDismissWithButtonIndex:buttonIndex];
    // the one place we release the window we allocated in "show"
    // this will propogate releases to us (TSAlertView), and our
    // TSAlertViewController
    [[self window] release];
}

// pulse animation thanks to:
// http://delackner.com/blog/2009/12/mimicking-uialertviews-animated-transition
- (void)pulse
{
    [self setTransform:CGAffineTransformMakeScale(.6, .6)];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:
            @selector(pulseDidStop1:finished:context:)];
    [self setTransform:CGAffineTransformMakeScale(1.1, 1.1)];
    [UIView commitAnimations];
}

- (void)pulseDidStop1:(NSString *)animationID
            finished:(NSNumber *)finished
             context:(void *)context
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1. / 15.];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:
            @selector(pulseDidStop2:finished:context:)];
    [self setTransform:CGAffineTransformMakeScale(.9, .9)];
    [UIView commitAnimations];
}

- (void)pulseDidStop2:(NSString *)animationID
            finished:(NSNumber *)finished
             context:(void *)context
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1. / 7.5];
    [self setTransform:CGAffineTransformIdentity];
    [UIView commitAnimations];
}

- (CGSize)titleLabelSize
{
    CGFloat maxWidth = [self width] - (kTSAlertView_LeftMargin * 2.);
    CGSize size = 
            [[[self titleLabel] text] sizeWithFont:[[self titleLabel] font]
                constrainedToSize:CGSizeMake(maxWidth, 1000.)
                lineBreakMode:[[self titleLabel] lineBreakMode]];

    if (size.width < maxWidth)
        size.width = maxWidth;
    return size;
}

- (CGSize)messageLabelSize
{
    CGFloat maxWidth = self.width - (kTSAlertView_LeftMargin * 2.);
    CGSize size =
            [[[self messageLabel] text] sizeWithFont:[[self messageLabel] font]
                constrainedToSize:CGSizeMake(maxWidth, 1000.)
                lineBreakMode:[[self messageLabel] lineBreakMode]];

    if (size.width < maxWidth)
        size.width = maxWidth;
    return size;
}

- (CGSize)inputTextFieldSize
{
    if ([self style] == TSAlertViewStyleNormal)
        return CGSizeZero;
    
    CGFloat maxWidth = [self width] - (kTSAlertView_LeftMargin * 2.);
    CGFloat totalHeight = .0;

    for (UITextField *textField in [self textFields])
        totalHeight += [[self inputTextField] sizeThatFits:CGSizeZero].height +
                kTSAlertView_RowMargin;
    return CGSizeMake(maxWidth, totalHeight);
}

- (CGSize)buttonsAreaSize_Stacked
{
    CGFloat maxWidth = [self width] - (kTSAlertView_LeftMargin * 2.);
    int buttonCount = [[self buttons] count];
    CGSize bs = [[self.buttons objectAtIndex:0] sizeThatFits:CGSizeZero];
    
    bs.width = maxWidth;
    bs.height = (bs.height * buttonCount) +
            kTSAlertView_RowMargin * (buttonCount - 1.);
    return bs;
}

- (CGSize)buttonsAreaSize_SideBySide
{
    CGFloat maxWidth = self.width - (kTSAlertView_LeftMargin * 2.);
    CGSize bs = [[self.buttons objectAtIndex:0] sizeThatFits:CGSizeZero];

    bs.width = maxWidth;
    return bs;
}

- (CGSize)recalcSizeAndLayout:(BOOL)layout
{
    BOOL stacked = !([self buttonLayout] == TSAlertViewButtonLayoutNormal &&
            [[self buttons] count] == 2);
    CGFloat maxWidth = [self width] - (kTSAlertView_LeftMargin * 2.);
    CGSize  titleLabelSize = [self titleLabelSize];
    CGSize  messageViewSize = [self messageLabelSize];
    CGSize  inputTextFieldSize = [self inputTextFieldSize];
    CGSize  buttonsAreaSize = stacked ? [self buttonsAreaSize_Stacked] :
            [self buttonsAreaSize_SideBySide];
    CGFloat inputRowHeight = [self style] == TSAlertViewStyleInput ?
            inputTextFieldSize.height + kTSAlertView_RowMargin : .0;
    CGFloat totalHeight = kTSAlertView_TopMargin + titleLabelSize.height +
            kTSAlertView_RowMargin + messageViewSize.height + inputRowHeight +
            kTSAlertView_RowMargin + buttonsAreaSize.height +
            kTSAlertView_BottomMargin;
    
    if (totalHeight > self.maxHeight) {
        // too tall - we'll condense by using a textView (with scrolling) for
        // the message
        totalHeight -= messageViewSize.height;
        //$$what if it's still too tall?
        messageViewSize.height = [self maxHeight] - totalHeight;
        totalHeight = [self maxHeight];
    }
    if (layout) {
        // title
        CGFloat y = kTSAlertView_TopMargin;

        if ([self title] != nil) {
            [[self titleLabel] setFrame:CGRectMake(kTSAlertView_LeftMargin, y,
                    titleLabelSize.width, titleLabelSize.height)];
            [self addSubview:[self titleLabel]];
            y += titleLabelSize.height + kTSAlertView_RowMargin;
        }
        // message
        if ([self message] != nil) {
            if ([self usesMessageTextView]) {
                [[self messageTextView] setFrame:
                        CGRectMake(kTSAlertView_LeftMargin, y,
                            messageViewSize.width, messageViewSize.height)];
                [self addSubview:[self messageTextView]];
                y += messageViewSize.height + kTSAlertView_RowMargin;
                
                UIImageView *maskImageView = [self messageTextViewMaskView];

                [maskImageView setFrame:[[self messageTextView] frame]];
                [self addSubview:maskImageView];
            } else {
                [[self messageLabel] setFrame:
                        CGRectMake(kTSAlertView_LeftMargin, y,
                            messageViewSize.width, messageViewSize.height)];
                [self addSubview:[self messageLabel]];
                y += messageViewSize.height + kTSAlertView_RowMargin;
            }
        }
        // input
        if ([self style] == TSAlertViewStyleInput) {
            for (UITextField *textField in [self textFields]) {
                CGSize textFieldSize = [textField sizeForAlertView:self];

                [textField setFrame:CGRectMake(kTSAlertView_LeftMargin, y,
                            textFieldSize.width,
                            textFieldSize.height)];
                [self addSubview:textField];
                y += textFieldSize.height + kTSAlertView_RowMargin;
            }
        }

        // buttons
        CGFloat buttonHeight =
                [[[self buttons] objectAtIndex:0]
                    sizeThatFits:CGSizeZero].height;

        if (stacked) {
            CGFloat buttonWidth = maxWidth;

            for (UIButton *b in [self buttons]) {
                [b setFrame:CGRectMake(kTSAlertView_LeftMargin, y, buttonWidth,
                        buttonHeight)];
                [self addSubview:b];
                y += buttonHeight + kTSAlertView_RowMargin;
            }
        } else {
            CGFloat buttonWidth = (maxWidth - kTSAlertView_ColumnMargin) / 2.;
            CGFloat x = kTSAlertView_LeftMargin;

            for (UIButton *b in [self buttons]) {
                [b setFrame:CGRectMake(x, y, buttonWidth, buttonHeight)];
                [self addSubview:b];
                x += buttonWidth + kTSAlertView_ColumnMargin;
            }
        }
    }
    return CGSizeMake([self width], totalHeight);
}

- (void)onKeyboardWillShow:(NSNotification *)note
{
    NSValue *boundsValue =
            [[note userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
    NSValue *centerValue =
            [[note userInfo] objectForKey:UIKeyboardCenterEndUserInfoKey];
    CGPoint kbCenter = [[self superview] convertPoint:[centerValue CGPointValue]
            fromView:nil];
    CGRect kbBounds = [boundsValue CGRectValue];
    CGRect kbFrame = CGRectOffset(kbBounds,
            kbCenter.x - kbBounds.size.width / 2.,
            kbCenter.y - kbBounds.size.height / 2.);
    
    if (CGRectIntersectsRect([self frame], kbFrame)) {
        CGPoint c = [self center];
        
        if ([self frame].size.height > kbFrame.origin.y - 20.) {
            [self setMaxHeight:kbFrame.origin.y - 20.];
            [self sizeToFit];
            [self layoutSubviews];
        }
        c.y = kbFrame.origin.y / 2.;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:.2];
        [self setCenter:c];
        [self setFrame:CGRectIntegral(self.frame)];
        [UIView commitAnimations];
    }
}

- (void)onKeyboardWillHide:(NSNotification *)note
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.2];
    CGRect bounds = [[self superview] bounds];

    [self setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [self setFrame:CGRectIntegral([self frame])];
    [UIView commitAnimations];
}

- (void)onButtonPress:(id)sender
{
    int buttonIndex = [_buttons indexOfObjectIdenticalTo:sender];
    
    if ([[self delegate] respondsToSelector:
            @selector(alertView:clickedButtonAtIndex:)])
        [[self delegate] alertView:self clickedButtonAtIndex:buttonIndex];
    if (buttonIndex == [self cancelButtonIndex] &&
            [[self delegate] respondsToSelector:@selector(alertViewCancel:)])
        [[self delegate] alertViewCancel:self];
    [self dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (void)setTextFieldProperties:(UITextField **)textField
{
    [*textField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [*textField setBorderStyle:UITextBorderStyleRoundedRect];
}

#pragma mark TSAlertView (Public)

@synthesize delegate = _delegate;
@synthesize backgroundImage = _backgroundImage;
@synthesize cancelButtonIndex = _cancelButtonIndex;
@synthesize buttonLayout = _buttonLayout;
@synthesize firstOtherButtonIndex = _firstOtherButtonIndex;
@synthesize shouldNotAdmitBlanks = _shouldNotAdmitBlanks;
@synthesize usesMessageTextView = _usesMessageTextView;
@synthesize width = _width;
@synthesize maxHeight = _maxHeight;
@synthesize style = _style;
@synthesize userInfo = _userInfo;

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    // Will call into initWithFrame, thus TSAlertView_commonInit is called
    if ((self = [super init]) != nil) {
        [self setTitle:title];
        [self setMessage:message];
        [self setDelegate:delegate];
        [self setUsesMessageTextView:YES];
        if (nil != cancelButtonTitle) {
            [self addButtonWithTitle:cancelButtonTitle];
            [self setCancelButtonIndex:.0];
        }
        
        if (nil != otherButtonTitles) {
            _firstOtherButtonIndex = [self.buttons count];
            [self addButtonWithTitle: otherButtonTitles];
            
            va_list args;
            va_start(args, otherButtonTitles);
            id arg;

            while (nil != (arg = va_arg(args, id))) {
                if (![arg isKindOfClass:[NSString class]])
                    return nil;
                [self addButtonWithTitle:(NSString*)arg];
            }
        }
    }
    return self;
}

- (void)setWidth:(CGFloat)width
{
    if (_width <= 0)
        _width = 284;
    _width = MAX(width, [[self backgroundImage] size].width);
}

- (CGFloat)width
{
    if (nil == [self superview])
        return _width;
    
    CGFloat maxWidth = [[self superview] bounds].size.width - 20;
    
    return MIN(_width, maxWidth);
}

- (void)setMaxHeight:(CGFloat)height
{
    if (height <= 0)
        height = 358;
    _maxHeight = MAX(height, [[self backgroundImage] size].height);
}

- (CGFloat)maxHeight
{
    if (nil == [self superview])
        return _maxHeight;
    return MIN(_maxHeight, [[self superview] bounds].size.height - 20);
}

- (void)setStyle:(TSAlertViewStyle)style
{
    if (_style != style) {
        _style = style;
        if (style == TSAlertViewStyleInput) {
            // need to watch for keyboard
            [[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(onKeyboardWillShow:)
                    name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(onKeyboardWillHide:)
                    name:UIKeyboardWillHideNotification object:nil];
        }
    }
}

- (UITextField *)inputTextField
{
    if (_textFields == nil) {
        UITextField *inputTextField = [[[UITextField alloc] init] autorelease];

        _textFields = [[NSMutableArray alloc] init];
        [self addTextField:inputTextField];
    }
    return [_textFields objectAtIndex:0];
}

- (UIImage *)backgroundImage
{
    if (_backgroundImage == nil) {
        [self setBackgroundImage:
                [[UIImage imageNamed: @"TSAlertViewBackground.png"]
                    stretchableImageWithLeftCapWidth:15 topCapHeight:30]];
    }
    return _backgroundImage;
}

- (void)setTitle:(NSString *)title
{
    [[self titleLabel] setText:title];
}

- (NSString*)title 
{
    return [[self titleLabel] text];
}

- (void)setMessage:(NSString *)message
{
    [[self messageLabel] setText:message];
    [[self messageTextView] setText:message];
}

- (NSString *)message  
{
    return [[self messageLabel] text];
}

- (NSInteger)numberOfButtons
{
    return [[self buttons] count];
}

- (void)setCancelButtonIndex:(NSInteger)buttonIndex
{
    // avoid a NSRange exception
    if (buttonIndex < 0 || buttonIndex >= [[self buttons] count])
        return;
    _cancelButtonIndex = buttonIndex;
    
    UIButton *b = [[self buttons] objectAtIndex:buttonIndex];
    UIImage *buttonBgNormal =
            [UIImage imageNamed:@"TSAlertViewCancelButtonBackground.png"];

    buttonBgNormal = [buttonBgNormal
            stretchableImageWithLeftCapWidth:[buttonBgNormal size].width / 2.
            topCapHeight:[buttonBgNormal size].height / 2.];
    [b setBackgroundImage:buttonBgNormal forState:UIControlStateNormal];
    
    UIImage *buttonBgPressed =
            [UIImage imageNamed:@"TSAlertViewButtonBackground_Highlighted.png"];

    buttonBgPressed = [buttonBgPressed
            stretchableImageWithLeftCapWidth:[buttonBgPressed size].width / 2.
            topCapHeight:[buttonBgPressed size].height / 2.];
    [b setBackgroundImage:buttonBgPressed forState:UIControlStateHighlighted];
}

- (BOOL)isVisible
{
    return [self superview] != nil;
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    UIButton *b = [UIButton buttonWithType: UIButtonTypeCustom];

    [b setTitle:title forState:UIControlStateNormal];
    
    UIImage* buttonBgNormal =
            [UIImage imageNamed: @"TSAlertViewButtonBackground.png"];

    buttonBgNormal = [buttonBgNormal
            stretchableImageWithLeftCapWidth:[buttonBgNormal size].width / 2.
            topCapHeight:[buttonBgNormal size].height / 2.];
    [b setBackgroundImage:buttonBgNormal forState:UIControlStateNormal];
    
    UIImage* buttonBgPressed =
            [UIImage imageNamed:@"TSAlertViewButtonBackground_Highlighted.png"];

    buttonBgPressed = [buttonBgPressed
            stretchableImageWithLeftCapWidth:buttonBgPressed.size.width / 2.
            topCapHeight:[buttonBgPressed size].height / 2.];
    [b setBackgroundImage:buttonBgPressed forState:UIControlStateHighlighted];
    [b addTarget:self action:@selector(onButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [[self buttons] addObject:b];
    [self setNeedsLayout];
    return [[self buttons] count] - 1;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
    // avoid a NSRange exception
    if (buttonIndex < 0 || buttonIndex >= [self.buttons count])
        return nil;
    
    UIButton* b = [self.buttons objectAtIndex:buttonIndex];
    
    return [b titleForState:UIControlStateNormal];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex
                             animated:(BOOL)animated
{
    BOOL shouldContinue = YES;
    NSUInteger shouldNotAdmitBlanks = [self shouldNotAdmitBlanks];

    if ([self style] == TSAlertViewStyleInput && shouldNotAdmitBlanks) {
        NSArray *textFields = [self textFields];
        NSUInteger i, count = [textFields count], mask = (NSUInteger)-1;

        for (i = 0; i < count; i++) {
            if (!(mask & shouldNotAdmitBlanks >> i))
                continue;

            UITextField *textField = [textFields objectAtIndex:i];
            NSString *text = [textField text];

            if (text == nil || [text isBlank]) {
                shouldContinue = NO;
                break;
            }
        }
    }
    if (shouldContinue) {
        if ([[self delegate] respondsToSelector:
                @selector(alertView:willDismissWithButtonIndex:)])
            [[self delegate] alertView:self
                    willDismissWithButtonIndex:buttonIndex];
        if (animated) {
            [[self window] setBackgroundColor:[UIColor clearColor]];
            [[self window] setAlpha:1.];
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:.2];
            [[self window] resignKeyWindow];
            [[self window] setAlpha:.0];
            [self releaseWindow:buttonIndex];
            [UIView commitAnimations];
        } else {
            [[self window] resignKeyWindow];
            [self releaseWindow:buttonIndex];
        }
        // Force keyboard dismissal
        [[self textFields] makeObjectsPerformSelector:
                @selector(resignFirstResponder)];
    }
}

- (void)show
{
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate date]];
    
    TSAlertViewController* avc =
            [[[TSAlertViewController alloc] init] autorelease];

    [[avc view] setBackgroundColor:[UIColor clearColor]];

    // $important - the window is released only when the user clicks an alert
    // view button
    TSAlertOverlayWindow* ow =
            [[TSAlertOverlayWindow alloc] initWithFrame:
                [[UIScreen mainScreen] bounds]];

    [ow setAlpha:.0];
    [ow setBackgroundColor:[UIColor clearColor]];
    [ow setRootController:avc];
    [ow makeKeyAndVisible];
    // fade in the window
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.2];
    [ow setAlpha:1.];
    [UIView commitAnimations];
    // add and pulse the alertview
    // add the alertview
    [[avc view] addSubview:self];
    [self sizeToFit];
    [self setCenter:CGPointMake(CGRectGetMidX(avc.view.bounds),
            CGRectGetMidY(avc.view.bounds))];
    [self setFrame:CGRectIntegral(self.frame)];
    [self pulse];
    
    if (self.style == TSAlertViewStyleInput) {
        [self layoutSubviews];
        [[self inputTextField] becomeFirstResponder];
    }
}
@end

@implementation TSAlertView (TSCustomizableAlertView)

#pragma mark -
#pragma mark TSAlertView (TSCustomizableAlertView)

- (NSInteger)numberOfTextFields
{
    return [[self textFields] count];
}

- (UITextField *)firstTextField
{
    if ([self numberOfTextFields] > 0) {
        return [self textFieldAtIndex:0];
    } else {
        return nil;
    }
}

- (void)addTextField:(UITextField *)textField
{
    NSMutableArray *textFields = [self textFields];

    [self setTextFieldProperties:&textField];
    // Set shouldNotAdmitBlanks correspondent flag for this UITextField
    [self setShouldNotAdmitBlanks:
            [self shouldNotAdmitBlanks] + (1 << [textFields count])];
    [textFields addObject:textField];
    
}

- (UITextField *)addTextFieldWithLabel:(NSString *)label
{
    return [self addTextFieldWithLabel:label value:nil];
}

- (UITextField *)addTextFieldWithLabel:(NSString *)label value:(NSString *)value
{
    UITextField *textField =
            [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];

    [textField setPlaceholder:label];
    [textField setText:value];
    [self addTextField:textField];
    return textField;
}

- (UITextField *)textFieldAtIndex:(NSInteger)index
{
    return [[self textFields] objectAtIndex:index];
}
@end
