//
//  SubscriptionManager.m
//
//  Created by SARATH DR on 26/02/2013.
//
//

#import "SubscriptionManager.h"

@implementation SubscriptionManager

static SubscriptionManager * _scManager; 

@synthesize request = _request;
@synthesize subscription = _subscription;
@synthesize productId = _productId;
@synthesize productIdentifier = _productIdentifier;
@synthesize callbackId = _callbackId;


static bool hasAddObserver=NO;


- (id)init: (NSString *) prodId  {
    
    _productId = prodId;
    _productIdentifier = [NSSet setWithObject:_productId ];
    return self;
    
}


-(void) requestProductData
{
   
    NSLog(@"Start: %@" , @" Request data called ");
    
    self.request = [[[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifier] autorelease];
    self.request.delegate = self;
    [self.request start];
    
    NSLog(@"Start: %@" , @" Request data ends ");
    
}


-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
    NSLog(@"Start: %@" , @" Request data received ");
    
    NSArray *products = response.products;
    self.subscription = [products count] == 1 ? [[products firstObject] retain] : nil;
    NSString *notifyValue       = [[NSUserDefaults standardUserDefaults] stringForKey:@"statusNotify" ];
    
   
    // This code is only if you do not want to show the product the details at this point.
    // If you want to show the product deatils change the notfyValue status to SUBSCRIPTION_STARTED after user confirm subscription
    // And write a separate function to add payment.
    
    if (self.subscription && [notifyValue isEqualToString:@"SUBSCRIPTION_STARTED"] )
    {
        NSLog(@"Product title: %@" , _subscription.localizedTitle);
        NSLog(@"Product description: %@" , _subscription.localizedDescription);
        NSLog(@"Product price: %@" , _subscription.price);
        NSLog(@"Product id: %@" , _subscription.productIdentifier);
        
        SKPayment *payment = [SKPayment paymentWithProduct:self.subscription];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        
    }
    
    

}


-(void) subscribe :(CDVInvokedUrlCommand*)command
{

    NSString *notifyValue       = [[NSUserDefaults standardUserDefaults] stringForKey:@"statusNotify" ];
    NSString *receiptData       = [[NSUserDefaults standardUserDefaults]  stringForKey:@"TransactionReceipt" ];
    NSString *javaScript = nil;
    
    NSString* prodId  = [command.arguments objectAtIndex:0];
    
    
    
    // Initialicses the product Ids
    [self init:prodId ];
    
    // Stores the callback ID
    [self.callbackId =   command.callbackId retain];
    

    // Checks for the status to make payments
    if ([SKPaymentQueue canMakePayments])
    {
        // New subscription
        if(    [notifyValue isEqualToString:@"SUBSCRIPTION_STARTED"]
            || notifyValue == nil
            || [notifyValue isEqualToString:@"SUBSCRIPTION_NOTIFIED"]
            || [notifyValue isEqualToString:@"SUBSCRIPTION_FAILED"])
        {

            
            
                if( ! [notifyValue isEqualToString: @"SUBSCRIPTION_STARTED"]   )
                {
                    
                    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                    [[NSUserDefaults standardUserDefaults] setValue:@"SUBSCRIPTION_STARTED" forKey:@"statusNotify" ];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    // Request Data from Here
                    [self requestProductData];
                    
                 }
                else{
                    
                    CDVPluginResult* pluginResult = nil;
                    NSString *message  = @"Something went wrong, please contact the support team.";
                    
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
                    
                    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                    //  [self release];
                    
                    }

            
            
        }
        else if( [notifyValue isEqualToString:@"SUBSCRIPTION_FINISHED"] &&  receiptData != nil ){
            
            CDVPluginResult* pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:receiptData];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];

        }
        else{

            CDVPluginResult* pluginResult = nil;
            NSString *message  = @"Something went wrong, please contact the support team.";
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
            
            [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
          //  [self release];

        }
    
    }
    else {
        
        CDVPluginResult* pluginResult = nil;
        NSString* javaScript = nil;
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The payment is disabled on your phone"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
       // [self release];
        
    }
    
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction
            wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if (wasSuccessful)
    {
        NSLog(@"Payment: %@" , @"Payment Success ");
        
        NSString *encodedString = [[NSUserDefaults standardUserDefaults]  stringForKey:@"TransactionReceipt" ];
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"paymentSuccess" ];
        [self sendDataToApp:encodedString ];
        
    }
    else
    {
        
        NSLog(@"Payment: %@" , @"Payment Failed");
    }
}

//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{


    NSLog(@"Start: %@" , @"Complete transaction called");
    [self recordTransaction:transaction];
    [self finishTransaction:transaction wasSuccessful:YES];
}



//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{

    
    NSLog(@"Product Receipt: %@" , @"Recording Called" );
    
    if ([transaction.payment.productIdentifier isEqualToString:self.productId ])
    {
        NSLog(@"Product Receipt: %@" , @"Reched recording" );
        NSData *receiptData = [NSData dataWithData:transaction.transactionReceipt];
        
        // Encode to Base64
        [Base64 initialize];
        NSString *encodedString = [Base64 encode:receiptData];

        NSLog(@"Product Receipt Encoded: %@" , encodedString );
        
        NSString *receiptStr = [[NSString alloc] initWithData:receiptData encoding:NSUTF8StringEncoding];
        

        NSLog(@"Product Receipt: %@" , receiptStr );
        
        
        
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] setValue:encodedString forKey:@"TransactionReceipt" ];
        [[NSUserDefaults standardUserDefaults] setValue:@"SUBSCRIPTION_FINISHED" forKey:@"statusNotify" ];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void) sendDataToApp:( NSString *) receipt
{
    NSLog(@"data send: %@" , @"Send Data called" );
    
    CDVPluginResult* pluginResult = nil;
    NSString* javaScript = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:receipt];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
   //  [self release];
    
}



//
// called when a transaction has been restored and and successfully completed
//
-(void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    
     NSLog(@"Start: %@" , @" payment restore called ");
    [self recordTransaction:transaction.originalTransaction];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"Start: %@" , @" payment failed called ");
    
    NSString *transactionFailed = @"I have no idea --- ";
    
    
    if (transaction.error.code == SKErrorPaymentCancelled){
        transactionFailed = @"Transaction failed => Payment cancelled.";
    }else if (transaction.error.code == SKErrorPaymentInvalid){
        transactionFailed = @"Transaction failed => Payment invalid.";
    }else if (transaction.error.code == SKErrorPaymentNotAllowed){
        transactionFailed = @"Transaction failed => Payment not allowed.";
    }else if (transaction.error.code == SKErrorClientInvalid){
        transactionFailed = @"Transaction failed => client invalid.";
    }else if (transaction.error.code == SKErrorUnknown){
        transactionFailed = @"Transaction failed => unknown error.";
    }

    NSLog(@"Transacation Failed: %@" , transactionFailed );
    
    [[NSUserDefaults standardUserDefaults] setValue:@"SUBSCRIPTION_FAILED" forKey:@"statusNotify" ];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // This is fine, the user just cancelled, so don’t notify
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    CDVPluginResult* pluginResult = nil;
    
    NSString *message = @"The transaction has been failed, please try again.";
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
   
}


//
// called when the transaction status is updated
//
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"Start: %@" , @" payment queue called ");
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                    NSLog(@"Start: %@" , @" Payment response completed  ");
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                                    NSLog(@"Start: %@" , @" Payment response failed  ");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                                    NSLog(@"Start: %@" , @" Payment response restored  ");
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions{
   
    for (SKPaymentTransaction *transaction in transactions)
    {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
    
    
    
    
}



- (void)dealloc
{
    [_productIdentifier release];
    _productIdentifier = nil;
    [_productId release];
    _productId = nil;
    [_callbackId release];
    _callbackId = nil;
    [_request release];
    _request = nil;
    [super dealloc];

}

@end