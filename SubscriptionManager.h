//
//  SubscriptionManager.h
//  Created by SARATH DR on 26/02/2013.
//
//
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVPluginResult.h>
#import <StoreKit/StoreKit.h>
#import <Foundation/Foundation.h>
#import "Base64.h"


@interface SubscriptionManager : CDVPlugin <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSSet * productIdentifier;
    SKProductsRequest * request;
    SKProduct *subscription;
    NSString *productId;
    NSString *callBackId;
}

@property (retain) NSSet *productIdentifier;
@property (retain) SKProductsRequest *request;
@property (retain) SKProduct *subscription;
@property (retain) NSString *productId;
@property (nonatomic,retain) NSString *callbackId;

-(void) subscribe :(CDVInvokedUrlCommand*)command;
-(void) dealloc;

@end
