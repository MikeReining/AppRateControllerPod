//
//  AppRateController.m
//  UniversalImagePickerApp
//
//  Created by Sergey Gerasimov on 4/20/17.
//  Copyright © 2017 Sergey Gerasimov. All rights reserved.
//

/*

Each time the user closes the settings page we present a rate us nag screen - With a few exceptions.

First, we don't present the nag screen the first time. That's too soon.

After the first time, we then either present Apple's nag (if it is supposed to fire according to Grigory's simple counter) OR our own custom nag screen (mockup attached and code below)

NOTE: For our own custom rate us nag screen, we should track if users have rated the existing version. We can just store that in userdefaults. They rated it if they pressed to rate the app in the alterView. if they have rated the current version, all nag screens disappear. Once a new version is launched, they all appear again.

*/


#import "AppRateController.h"

@import StoreKit;

#define AppRateIsIOSVersionGreaterThanOrEqualTo(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@interface AppRateController ()
{
	BOOL _isNeedToRate;
	
	//Settings
	NSUInteger _callsNumberBeforeFirstRate;
	NSUInteger _repeatRateInterval;
	
	//Statistics
	NSUInteger _attemptsCount;
	
	NSString* _applicationId;
}
@end



@implementation AppRateController

+ (AppRateController*)sharedAppRateController
{
    static dispatch_once_t onceToken;
    static AppRateController* appRateController;
    dispatch_once(&onceToken, ^{
        appRateController = [[self alloc] init];
    });
    return appRateController;
}

+ (void)useItunesApplicationIdentifier:(NSString*)identifier
{
	[[AppRateController sharedAppRateController] useApplicationId:identifier];
}

+ (void)showRateAlertUsingViewController:(UIViewController*)viewController
{
	[[AppRateController sharedAppRateController] showRateAlertInViewController:viewController];
}

+ (NSURL*)applicationStoreRateURL
{
	return [[AppRateController sharedAppRateController] getAppRateURL];
}

+ (void)openApplicationRatePage
{
	return [[AppRateController sharedAppRateController] openRatePage];
}

- (instancetype)init
{
	if ((self = [super init]))
	{
		_callsNumberBeforeFirstRate = 5;
		_repeatRateInterval = 3;
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_attemptsCount"])
		{
			_attemptsCount = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_attemptsCount"] integerValue];
		}
		else
		{
			_attemptsCount = 0;
		}
	}
	
	return self;
}

- (void)useApplicationId:(NSString*)appId
{
	_applicationId = appId;
}

- (void)showRateAlertInViewController:(UIViewController*)viewController
{
	[self registerRateAttempt];
	
	if (_isNeedToRate)
	{
		if (AppRateIsIOSVersionGreaterThanOrEqualTo(@"10.3"))
		{
            if ((_attemptsCount / _repeatRateInterval) < 3) // first try to capture star rating since it is easier to get
            {
                [SKStoreReviewController requestReview];
            }
            else // then try to capture written review which is harder to get
            {
                if (![self wasRatedByWriteReviewAlertController])
                {
                    [self showWriteReviewAlertUsingViewController:viewController];
                }
            }
		}
		else if (![self wasRatedByFallbackAlertController])
		{
			[self showFallbackAlertUsingViewController:viewController];
		}
		else
		{
			NSLog(@"App was already rated");
		}
	}
	else
	{
		NSLog(@"App rating don't needed");
	}
}

- (void)registerRateAttempt
{
	_attemptsCount++;
	_isNeedToRate = NO;
	
	if (_attemptsCount >= _callsNumberBeforeFirstRate)
	{
		if (_attemptsCount == _callsNumberBeforeFirstRate)
		{
			_isNeedToRate = YES;
		}
		else if (((_attemptsCount - _callsNumberBeforeFirstRate) % _repeatRateInterval) == 0)
		{
			_isNeedToRate = YES;
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:@(_attemptsCount) forKey:@"AppRateController_attemptsCount"];
}

- (BOOL)wasRatedByWriteReviewAlertController
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_bundleID"] &&
		[[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_bundleVersion"] &&
		[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_bundleID"] isEqualToString:[self getBundleID]] &&
		[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppRateController_bundleVersion"] isEqualToString:[self getBundleVersion]])
	{
		return YES;
	}
	
	return NO;
}

- (NSString*)getBundleID
{
	NSDictionary* info_dict = [[NSBundle mainBundle] infoDictionary];
	NSString* bundle_id = [info_dict objectForKey:@"CFBundleIdentifier"];
	return bundle_id;
}

- (NSString*)getBundleVersion
{
	NSDictionary* info_dict = [[NSBundle mainBundle] infoDictionary];
	NSString* bundle_version = [info_dict objectForKey:@"CFBundleShortVersionString"];
	return bundle_version;
}

- (NSURL*)getAppRateURL
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/us/app/apple-store/viewContentsUserReviews?id=\%@&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8", _applicationId]];
}

- (void)openRatePage
{
	[[NSUserDefaults standardUserDefaults] setObject:[self getBundleID] forKey:@"AppRateController_bundleID"];
	[[NSUserDefaults standardUserDefaults] setObject:[self getBundleVersion] forKey:@"AppRateController_bundleVersion"];
	
	[[UIApplication sharedApplication] openURL:[self getAppRateURL]];
}

- (void)showWriteReviewAlertUsingViewController:(UIViewController*)viewController
{
	UIAlertController* alert_vc = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Rate Us", @"")
		message:NSLocalizedString(@"Please take a minute to leave an honest review of our app in the App Store.  \n\n PS: Getting written reviews is incredibly helpful for small developers so thank you for making a difference!", @"")
		preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* action_rate = [UIAlertAction actionWithTitle:NSLocalizedString(@"Go rate app >", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		
		[self openRatePage];
	}];
	
	UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Later", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		
	}];
	
	[alert_vc addAction:action_rate];
	[alert_vc addAction:action_cancel];
	
	[viewController presentViewController:alert_vc animated:YES completion:^{
		
	}];
}

@end


