//
//  Application.m
//  TextViewLinks
//
//  Created by kishikawa katsumi on 2013/06/05.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "Application.h"

@implementation Application

- (BOOL)openURL:(NSURL *)url
{
    NSString *scheme = url.scheme;
    if ([scheme hasPrefix:@"http"]) {
        // 通常のリンクの処理
        NSLog(@"%@", url.absoluteString);
    } else if ([scheme isEqualToString:@"ftp"]) {
        // メンションの処理
        NSLog(@"%@", url.absoluteString);
    } else if ([scheme hasPrefix:@"maps"]) {
        // ハッシュタグの処理
        NSLog(@"%@", url.absoluteString);
    }
    return NO;
}

@end
