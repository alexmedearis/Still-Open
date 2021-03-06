	    //
//  PlacesListViewController.m
//  StillOpen
//
//  Created by Alexander Medearis on 6/26/10.
//  Copyright 2010 Alex Medearis. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PlacesListViewController.h"
#import "BusinessModel.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PlacesDetailViewController.h"
#import "LocationCell.h"
#import <FlurrySDK/Flurry.h>
#import <Optimizely/Optimizely.h>

@implementation PlacesListViewController

@synthesize openBusinesses = _openBusinesses;
@synthesize dataProvider = _dataProvider;
@synthesize pull = _pull;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.haveReceivedData = false;
        self.dataProvider = [[DataProvider alloc] initWithDataDelegate:self];
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.adBanner setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
	// Set custom image to nav bar
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headerlogo"]];
	self.navigationController.navigationBar.translucent = NO;
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0 green:0.2 blue:0.4 alpha:0];
    } else {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0 green:0.2 blue:0.4 alpha:0];
    }
    
	// Set backtround
    //[tView setBackgroundView:nil];
	self.tView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.4f];
    //tView.frame = CGRectMake(10, 40, 300, 380);
    [self.tView.layer setCornerRadius:8.0f];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    
    // Initialize HUD
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.HUD];
    
    self.pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tView];
    [self.pull setDelegate:self];
    [self.tView addSubview:self.pull];
    
    // Set Title and Background
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                UITextAttributeTextColor: [UIColor whiteColor],
                                     UITextAttributeFont: [UIFont fontWithName:@"LifeSavers-Regular" size:20.0]
     }];
    
    // Just show the chevron for title in iOS 7... Not a great solution but this will work for now
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.title = @"";

    }
    
    [Flurry logEvent:@"visitedMainScreen"];

    [self reload];
}

- (void) viewWillAppear:(BOOL)animated {
    [[Optimizely sharedInstance] codeTest:@"test" withBlocks:@{@"one" : ^{
        [Flurry logEvent:@"one"];
    },
                                                               @"two" : ^{
        [Flurry logEvent:@"two"];
        
    },
                                                               
                                                               }defaultBlock:^{
                                                                   [Flurry logEvent:@"three"];
                                                               }];
}

- (void) reload
{
    [self.HUD setDetailsLabelText:@"Getting Location..."];
    [self.HUD show:YES];
	[self.dataProvider getData];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self reload];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setAdBanner:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark -
#pragma mark DataReceiver Protocol
- (void) dataReceived:(NSMutableArray *) openBusinesses
{
    self.haveReceivedData = true;
	[self.HUD hide:YES];
	self.openBusinesses = openBusinesses;
	[self.tView reloadData];
    [self.pull finishedLoading];
}

- (void) locationReceived {
    [self.HUD setDetailsLabelText:@"Loading..."];
}

- (void)locationError {
    [self.HUD hide:YES];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @""
                          message: @"We were unable to verify your location.  Please verify that you have location services enabled, then try again."
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [self.pull finishedLoading];
}

- (void) errorOccurred {
    [self.HUD hide:YES];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @""
                          message: @"We were unable to fetch nearby locations.  Check your connection and then try again."
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [self.pull finishedLoading];
}

#pragma mark -
#pragma mark UITableViewDataSource Protocol

//  Returns the number of rows in the current section. 
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
        if(self.dataProvider.nextPageKey){
            return [self.openBusinesses count] + 1;
        } else if(self.openBusinesses.count == 0 && self.haveReceivedData){
            return 1;
        } else {
            return [self.openBusinesses count];
        }
	}
	else
	{
		return 0;
	}

}


// Return a cell containing the text to display at the provided row index.
//
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell"];
    
    if (cell == nil)
    {
        cell = [[LocationCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"MyCell"];
        
        //  Customize fonts
        
        UIFont *titleFont = [UIFont fontWithName:@"LifeSavers-Regular" size:16.0];
        [[cell textLabel] setFont:titleFont];
        [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
        
        UIFont *detailFont = [UIFont fontWithName:@"LifeSavers-Regular" size:10.0];
        [[cell detailTextLabel] setFont:detailFont];
        [[cell detailTextLabel] setBackgroundColor:[UIColor clearColor]];
    }
    
    NSUInteger index = [indexPath row];
    if(index < self.openBusinesses.count){
        BusinessModel * business = self.openBusinesses[index];
        [[cell textLabel] setText:business.name];
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f miles  %@", business.distance, business.address   ]];
        
        [cell.imageView setImageWithURL:[NSURL URLWithString:business.icon] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    } else if(self.openBusinesses.count == 0){
        cell.textLabel.text = @"No Places Found";
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    } else {
        cell.textLabel.text = @"Load More";
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
        [cell setAccessoryType:UITableViewCellAccessoryNone];

    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)path
{
    if (self.openBusinesses.count == 0)
    {
        return nil;
    }
    return path;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger index = [indexPath row];
    if(index < self.openBusinesses.count) {
        BusinessModel * business = self.openBusinesses[index];
        PlacesDetailViewController * detail = [[PlacesDetailViewController alloc] initWithNibName:@"PlacesDetail" bundle:[NSBundle mainBundle]
                                                                                         business:business locationProvider:self.dataProvider.locationProvider];
        
        [self.navigationController pushViewController:detail animated:YES];
    } else if(index == self.openBusinesses.count){
        [self.HUD show:YES];
        [self.dataProvider sendNextRequest];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    self.adBanner.hidden = YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
    self.adBanner.hidden = NO;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    
}


@end
