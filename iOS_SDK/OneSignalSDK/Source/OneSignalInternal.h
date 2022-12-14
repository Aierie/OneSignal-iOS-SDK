/**
 * Modified MIT License
 *
 * Copyright 2016 OneSignal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * 2. All copies of substantial portions of the Software may only be used in connection
 * with services provided by OneSignal.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


// Internal selectors to the OneSignal SDK to be shared by other Classes.

#ifndef OneSignalInternal_h
#define OneSignalInternal_h

#import "OneSignalFramework.h"
#import "OSObservable.h"
#import "OneSignalNotificationSettings.h"

#import "OSPermission.h"

@interface OneSignal (OneSignalInternal)

+ (BOOL)shouldPromptToShowURL;
+ (void)setIsOnSessionSuccessfulForCurrentState:(BOOL)value;
+ (BOOL)shouldRegisterNow;

+ (NSDate *_Nonnull)sessionLaunchTime;


@property (class, readonly) BOOL didCallDownloadParameters;
@property (class, readonly) BOOL downloadedParameters;
//Indicates we have attempted to register the user and it has succeeded or failed
@property (class, readonly) BOOL isRegisterUserFinished;
//Indicates that registering the user was successful
@property (class, readonly) BOOL isRegisterUserSuccessful;

@property (class) AppEntryAction appEntryState;
@property (class) OSSessionManager* _Nonnull sessionManager;

@end

#endif /* OneSignalInternal_h */
