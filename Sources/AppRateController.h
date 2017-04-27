//
//  AppRateController.h
//  UniversalImagePickerApp
//
//  Created by Sergey Gerasimov on 4/20/17.
//  Copyright © 2017 Sergey Gerasimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppRateController : NSObject

+ (void)useItunesApplicationIdentifier:(NSString*)identifier;
+ (void)showRateAlertUsingViewController:(UIViewController*)viewController;
+ (NSURL*)applicationStoreRateURL;
+ (void)openApplicationRatePage;

@end


