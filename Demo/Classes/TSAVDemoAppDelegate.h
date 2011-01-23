//
//  TSAVDemoAppDelegate.h
//  TSAVDemo
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//

#import <UIKit/UIKit.h>


@interface TSAVDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UINavigationController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;

@end

