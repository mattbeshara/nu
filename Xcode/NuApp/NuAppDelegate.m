//
//  NuAppDelegate.m
//  NuApp
//
//  Created by Tim Burks on 6/11/11.
//  Copyright 2011 Radtastical Inc. All rights reserved.
//

#import "NuAppDelegate.h"

#import "Nu.h"
#import "NuBlock.h"
#import "NuBridgedBlock.h"

#import <UIKit/UIKit.h>

@class ViewController;

@implementation NuAppDelegate
@synthesize window,view,log,interpreterListener;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSDictionary *environment = [[NSProcessInfo processInfo] environment];
	NSString *testConfigPath = environment[@"XCTestConfigurationFilePath"];
	if (testConfigPath)
		return YES;
	
	NSLog(@"inner");
	CGRect frame = [[UIScreen mainScreen] bounds];
	self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
	[self.window makeKeyAndVisible];
	UIViewController *viewController = [[UIViewController alloc] init];
	self.window.rootViewController = viewController;
	self.view = [[UIView alloc] initWithFrame:frame];
	viewController.view = self.view;

	CGRect logFrame = frame;
	logFrame.size.height -= 24;
	logFrame.origin.y += 24;
	self.log = [[UITextView alloc] initWithFrame:logFrame];
	self.log.backgroundColor = [UIColor clearColor];
	self.log.text = @"Not run yet";
	[self.view addSubview:self.log];
	self.view.backgroundColor = [UIColor whiteColor];

	[self prepareTests];
	int failures = [self runTests];
	if (failures == 0) {
		view.backgroundColor = [UIColor greenColor];
		self.log.text = @"Everything Nu!";
	} else {
		view.backgroundColor = [UIColor redColor];
		self.log.text = [NSString stringWithFormat:@"%d failures!",failures];
	}
	
	return YES;
}

- (void)log:(NSString *)message {
	log.text = [log.text stringByAppendingFormat:@"\n%@", message];
    [log scrollRangeToVisible:NSMakeRange(log.text.length - 2, 1)];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[self setupListener];
}

- (void)setupListener {
	self.interpreterListener = [[InterpreterListener alloc] init];

	self.interpreterListener.evalResultHandler = ^(id result) {
		[self log:[NSString stringWithFormat:@"%@", result]];
	};

	[self.interpreterListener listenWithCompletionHandler:^(uint16_t port) {
		if (port != 0) {
			[self log:[NSString stringWithFormat:@"Listening succeeded on port %i", port]];
		} else {
			[self log:@"Listening failed"];
		}
	}];
}

-(void)prepareTests
{
	NuInit();
	
	[[Nu sharedParser] parseEval:@"(load \"nu\")"];
	[[Nu sharedParser] parseEval:@"(load \"test\")"];
	
	NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
	
	NSArray *files = [[NSFileManager defaultManager]
					  contentsOfDirectoryAtPath:resourceDirectory
					  error:NULL];
	NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^test_.*nu$" options:0 error:NULL];
	for (NSString *filename in files) {
		NSUInteger numberOfMatches = [regex numberOfMatchesInString:filename
															options:0
															  range:NSMakeRange(0, [filename length])];
		if (numberOfMatches) {
			NSLog(@"loading %@", filename);
			NSString *s = [NSString stringWithContentsOfFile:[resourceDirectory stringByAppendingPathComponent:filename]
													encoding:NSUTF8StringEncoding
													   error:NULL];
			[[Nu sharedParser] parseEval:s];
		}
	}
	
	[regex release];
}

-(int)runTests
{
	int failures = 0;
	
	@try
	{
		NSLog(@"running tests");
		failures += [[[Nu sharedParser] parseEval:@"(NuTestCase runAllTests)"] intValue];
		
		failures++;
		
		NSString* script = @"(do () (puts \"cBlock Work!\"))";
		id parsed = [[Nu sharedParser] parse:script];
		NuBlock* block = [[Nu sharedParser] eval:parsed];
		void (^cblock)() = [NuBridgedBlock cBlockWithNuBlock:block	signature:@"v"];
		cblock();
		
		failures--;
		
	}
 	@catch (NSException *e)
	{
		NSLog(@"Exception: %@", e);
	}
	@finally {
		return failures;
	}
}

@end
