
#include <sys/types.h>
#include <sys/sysctl.h>
#include "TargetConditionals.h"

#import <QuartzCore/CoreAnimation.h>
#import <Cordova/CDV.h>
#import "PGMultiView.h"


#pragma mark PGMultiViewController - CDVViewController subclass

@implementation PGMultiViewController
@synthesize pgmDelegate = _pgmDelegate;


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (UIEventSubtypeMotionShake) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// - (void)viewDidLoad
// {
//     [super viewDidLoad];
//     CGRect webViewBounds = self.view.bounds;
//     webViewBounds.origin = self.view.bounds.origin;
//     webViewBounds.origin.x = 1;
//     webViewBounds.size.width = webViewBounds.size.width - 1;
//     self.webView.bounds = webViewBounds;
// }

@end


@implementation PGMultiView

@synthesize childViewController;


static NSString * _msg;
+ (NSString *)msg { return _msg; }
+ (void)setMsg:(NSString *)newValue { _msg = newValue; }



- (BOOL) shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

// TODO: override this, and use the config.xml for the currently loaded page
// also, add ALL orientations to the application
// - (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
// {
//     return [self.supportedOrientations containsObject:[NSNumber numberWithInt:orientation]];
// }

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if(viewController == self.viewController)
    {
        navigationController.navigationBarHidden = YES;
    }
    else
    {
        navigationController.navigationBarHidden = NO;
    }
}


#pragma mark JS Callable Plugin API

- (void)dismissView:(CDVInvokedUrlCommand*)command
{
    NSString* msg = [command argumentAtIndex:0];
    PGMultiViewController* topView = (PGMultiViewController*)[self.viewController.navigationController popViewControllerAnimated:YES];
    // seend the message back to our creator
    [topView.pgmDelegate dismissWithResult:msg];

    self.viewController.navigationController.navigationBarHidden = YES;
    childViewController = NULL;

    // When we get this message, we are dismissing the view so there is no need to use a callback into js
}

- (void)loadView:(CDVInvokedUrlCommand*)command
{
    childViewController = [[PGMultiViewController alloc] init];
    childViewController.pgmDelegate = self;
    childViewController.startPage = [command argumentAtIndex:0];

    // childViewController setMessage:[command argumentAtIndex:1]
    self.callbackId = command.callbackId;

    PGMultiView.msg = [command argumentAtIndex:1];

    // TODO: set proper config.xml -> childViewController.configFile

    if(self.viewController.navigationController == NULL)
    {
        UINavigationController* nav = [[UINavigationController alloc] init];
        nav.navigationBarHidden = NO;
        nav.delegate = self;
        self.webView.window.rootViewController = nav;
        [nav pushViewController:self.viewController animated:NO];
        nav.hidesBarsOnSwipe  = YES;
        nav.hidesBarsOnTap = YES;
    }

    [self.viewController.navigationController pushViewController:childViewController animated:YES];
}

- (void)getMessage:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:PGMultiView.msg];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)dismissWithResult:(NSString*)result
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

@end
