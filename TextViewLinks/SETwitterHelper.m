//
//  SETwitterHelper.m
//  SECoreTextView-Mac
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETwitterHelper.h"
#import "SECompatibility.h"

@implementation SETwitterHelper {
    NSCache *_attributedStringCache;
}

+ (SETwitterHelper *)sharedInstance
{
    static SETwitterHelper *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SETwitterHelper alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _attributedStringCache = [[NSCache alloc] init];
    }
    return self;
}

- (NSAttributedString *)attributedStringWithTweet:(NSDictionary *)tweet
{
    NSString *text = tweet[@"text"];
    if (!text) {
        return [[NSAttributedString alloc] init];
    }
    if ([_attributedStringCache objectForKey:text]) {
        return [_attributedStringCache objectForKey:text];
    }
    
    NSFont *tweetFont = [NSFont systemFontOfSize:14.0f];
    
    NSColor *tweetColor = [NSColor blackColor];
    NSColor *hashTagColor = [NSColor grayColor];
    
	NSDictionary *attributes = @{NSForegroundColorAttributeName: tweetColor, NSFontAttributeName: tweetFont};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    
    NSArray *textEentities = [TwitterText entitiesInText:text];
    for (TwitterTextEntity *textEentity in textEentities) {
        if (textEentity.type == TwitterTextEntityScreenName) {
            NSString *screenName = [text substringWithRange:textEentity.range];
            [attributedString addAttributes:@{
             @"NSLink": [NSString stringWithFormat:@"ftp:%@", screenName],
             NSForegroundColorAttributeName: [UIColor redColor]}
                                      range:textEentity.range];
        } else if (textEentity.type == TwitterTextEntityHashtag) {
            NSString *hashTag = [text substringWithRange:textEentity.range];
            [attributedString addAttributes:@{
             @"NSLink": [NSString stringWithFormat:@"maps:%@", hashTag],
             NSForegroundColorAttributeName: hashTagColor,
                        NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f]}
                                      range:textEentity.range];
        }
    }
    
    NSDictionary *entities = tweet[@"entities"];
    NSArray *urls = entities[@"urls"];
    for (NSDictionary *url in urls.reverseObjectEnumerator) {
        NSArray *indices = url[@"indices"];
        
        NSInteger first = [indices[0] integerValue];
        NSInteger last = [indices[1] integerValue];
        for (NSInteger i = 0; i < first; i++) {
            unichar c = [text characterAtIndex:i];
            if (CFStringIsSurrogateHighCharacter(c)) {
                first++;
                last++;
            }
        }
        for (NSInteger i = first; i < last; i++) {
            unichar c = [text characterAtIndex:i];
            if (CFStringIsSurrogateHighCharacter(c)) {
                last++;
            }
        }
        
        NSString *replace = url[@"display_url"];
        
        [attributedString replaceCharactersInRange:NSMakeRange(first, last - first) withString:replace];
        [attributedString addAttributes:@{NSLinkAttributeName: url[@"expanded_url"]}
                                  range:NSMakeRange(first, replace.length)];
    }
    
    NSDictionary *refs = @{@"&amp;": @"&", @"&lt;": @"<", @"&gt;": @">", @"&quot;": @"\"", @"&apos;": @"'"};
    for (NSString *key in refs.allKeys.reverseObjectEnumerator) {
        NSRange range = [attributedString.string rangeOfString:key];
        while (range.location != NSNotFound) {
            [attributedString replaceCharactersInRange:range withString:refs[key]];
            range = [attributedString.string rangeOfString:key];
        }
    }
    
    [_attributedStringCache setObject:attributedString forKey:text];
    
    return attributedString;
}

@end
