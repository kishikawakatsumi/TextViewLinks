//
//  ViewController.m
//  TextViewLinks
//
//  Created by kishikawa katsumi on 2013/06/05.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "ViewController.h"
#import "TimelineCell.h"
#import "SETwitterHelper.h"
#import "SEImageCache.h"

@interface ViewController ()

@property (strong, nonatomic) NSArray *timeline;
@property (strong, nonatomic) UITextView *sizingTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
     {
         if (granted) {
             NSArray *accounts = [accountStore accountsWithAccountType:accountType];
             
             if (accounts.count > 0) {
                 ACAccount *account = accounts[0];
                 [self getHomeTimlineWithAccount:account];
             }
         }
     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timeline.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tweet = self.timeline[indexPath.row];
    NSAttributedString *attributedString = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    
    if (!self.sizingTextView) {
        self.sizingTextView = [[UITextView alloc] init];
    }
    self.sizingTextView.attributedText = attributedString;
    CGSize fitSize = [self.sizingTextView sizeThatFits:CGSizeMake(260.0f, CGFLOAT_MAX)];
    
    return MAX(tableView.rowHeight, fitSize.height + 18.0f);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TimelineCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *tweet = self.timeline[indexPath.row];
    
    NSURL *iconURL = [NSURL URLWithString:tweet[@"user"][@"profile_image_url_https"]];
    UIImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                       defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                    completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image && [cell.profileIconURL isEqual:iconURL]) {
                                  cell.iconImageView.image = image;
                              }
                          }];
    cell.iconImageView.image = iconImage;
    cell.profileIconURL = iconURL;
    
    NSDictionary *user = tweet[@"user"];
    cell.screenNameLabel.text = user[@"name"];
    cell.nameLabel.text = [NSString stringWithFormat:@"@%@", user[@"screen_name"]];
    
    cell.tweetTextView.dataDetectorTypes = UIDataDetectorTypeLink;
//    cell.tweetTextView.text = tweet[@"text"];
    cell.tweetTextView.attributedText = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    
    return cell;
}

#pragma mark -

- (void)getHomeTimlineWithAccount:(ACAccount *)account
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
    NSDictionary *params = @{@"count": @"200", @"include_entities": @"true"};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:requestURL
                                               parameters:params];
    request.account = account;
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         
         if (error) {
             [self showAlertOnError:error];
             return;
         }
         
         NSError *parseError = nil;
         id result = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
         
         if (parseError) {
             [self showAlertOnError:parseError];
             return;
         }
         
         if ([result isKindOfClass:[NSDictionary class]]) {
             NSArray *errors = result[@"errors"];
             if (errors) {
                 NSInteger code = [((NSDictionary *)errors.lastObject)[@"code"] integerValue];
                 NSString *message = ((NSDictionary *)errors.lastObject)[@"message"];
                 
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
                 [self showAlertOnError:error];
                 return;
             }
         }
         
         if ([result isKindOfClass:[NSArray class]]) {
             self.timeline = result;
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [self.tableView reloadData];
                            });
             return;
         }
         
         [self showAlertOnError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey: @"Unknown error occurred."}]];
     }];
}

#pragma mark -

- (void)showAlertOnError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"SECoreTextView"
                                                                           message:error.localizedDescription
                                                                          delegate:self
                                                                 cancelButtonTitle:nil
                                                                 otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                       [alertView show];
                   });
}

@end
