//
//  LocationProvider.m
//  StillOpen
//
//  Created by Alexander Medearis on 7/2/10.
//  Copyright 2010 Alex Medearis. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LocationProvider.h"

// We can afford to be generous in terms of accuracy
#define MIN_ACCURACY 500.0

@implementation LocationProvider

@synthesize locationManager;

- (id) initWithLocationDelegate:(id<LocationReceiver>)delegate {
    self = [super init];
    if (self != nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self; // send loc updates to myself
		self.delegate = delegate;
    }
    return self;
}

-(void) getLocation
{
	self.hasReturnedLocation = false;
	[locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	// If we already returned a location for this time around, just return
	if(self.hasReturnedLocation)
	{
		return;
	}
	
	// Filter out nil locations
	if(!newLocation)
		return;
	
	// Make sure that the location returned has the desired accuracy
	if(newLocation.horizontalAccuracy > MIN_ACCURACY)
		return;
	
	// Filter out points that are out of order    
	if([newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp] < 0)
		return;
	
	// Also, make sure that the cached location was not returned by the CLLocationManager (it's current) - Check for 360 seconds difference
	if([newLocation.timestamp timeIntervalSinceReferenceDate] < [[NSDate date] timeIntervalSinceReferenceDate] - 360)
		return;
	

	[self.delegate locationReceived:newLocation];
	[locationManager stopUpdatingLocation];
	self.hasReturnedLocation = true;
	
	self.lastLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
    [self.delegate locationError];
}

- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D coord = {self.lastLocation.coordinate.latitude, self.lastLocation.coordinate.longitude};
	return coord;
}


- (void)dealloc {

}

@end
