
#import "ViewController.h"

@interface ViewController ()

@end


@implementation ViewController

+(NSString*)generateOrderIDWithPrefix:(NSString *)prefix
{
    srand ( (unsigned)time(NULL) );
    int randomNo = rand(); //just randomizing the number
    NSString *orderID = [NSString stringWithFormat:@"%@%d", prefix, randomNo];
    return orderID;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showController:(PGTransactionViewController *)controller
{
    if (self.navigationController != nil)
        [self.navigationController pushViewController:controller animated:YES];
    else
        [self presentViewController:controller animated:YES
                         completion:^{
                             
                         }];
}

-(void)removeController:(PGTransactionViewController *)controller
{
    if (self.navigationController != nil)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [controller dismissViewControllerAnimated:YES
                                       completion:^{
                                       }];
}

-(IBAction)testPayment:(id)sender
{
    
    NSString* urlString = @"http://paytmchecksum.co.nf/generateChecksum.php";
    NSString *params = @"ORDER_ID=00113000&CUST_ID=xxxxxxx@gmail.com&INDUSTRY_TYPE_ID=Retail&TXN_AMOUNT=100&EMAIL=xxxxxx@gmail.com&MOBILE_NO=xxxxxxxxxx";
    
    NSMutableURLRequest* urlRequest =  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil;
    NSURLResponse* response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (error) {
        NSLog(@"error:: %@",error);
    }
    NSLog( @"data: %@" , [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ) ;

    NSMutableDictionary *dict=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    NSString *myString = dict[@"CHECKSUMHASH"];
    NSLog( @"myString: %@" , myString ) ;
    NSLog( @"dict: %@" , dict) ;
    
    //Step 1: Create a default merchant config object
    PGMerchantConfiguration *mc = [PGMerchantConfiguration defaultConfiguration];
    //Step 2: Create the order with whatever params you want to add. But make sure that you include the merchant mandatory params
    NSMutableDictionary *orderDict = [NSMutableDictionary new];
    //Merchant configuration in the order object
    orderDict[@"MID"] = @"xxxx";
    orderDict[@"ORDER_ID"] = @"00113000";
    orderDict[@"CUST_ID"] = @"xxxx@gmail.com";
    orderDict[@"INDUSTRY_TYPE_ID"] = @"Retail";
    orderDict[@"CHANNEL_ID"] = @"WAP";
    orderDict[@"TXN_AMOUNT"] = @"100";
    orderDict[@"WEBSITE"] = @"APP_STAGING";
    orderDict[@"CALLBACK_URL"] = @"https://pguat.paytm.com/paytmchecksum/paytmCallback.jsp";
    orderDict[@"EMAIL"] = @"xxxx@gmail.com";
    orderDict[@"MOBILE_NO"] = @"xxxx";
    orderDict[@"CHECKSUMHASH"] = myString;
    
    PGOrder *order = [PGOrder orderWithParams:orderDict];
    
    //Step 3: Choose the PG server. In your production build dont call selectServerDialog. Just create a instance of the
    //PGTransactionViewController and set the serverType to eServerTypeProduction
    [PGServerEnvironment selectServerDialog:self.view completionHandler:^(ServerType eServerTypeProduction)
     {
         PGTransactionViewController *txnController = [[PGTransactionViewController alloc] initTransactionForOrder:order];
         
            //txnController.merchant = [PGMerchantConfiguration defaultConfiguration];
         
             txnController.serverType = eServerTypeProduction;
             txnController.merchant = mc;
             txnController.delegate = self;
             txnController.loggingEnabled = YES;
             [self showController:txnController];
     }];
}

#pragma mark PGTransactionViewController delegate

-(void)didFinishedResponse:(PGTransactionViewController *)controller response:(NSString *)responseString {
    DEBUGLOG(@"ViewController::didFinishedResponse:response = %@", responseString);
    NSString *title = [NSString stringWithFormat:@"Response"];
    [[[UIAlertView alloc] initWithTitle:title message:[responseString description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self removeController:controller];
}

- (void)didCancelTransaction:(PGTransactionViewController *)controller error:(NSError*)error response:(NSDictionary *)response
{
    DEBUGLOG(@"ViewController::didCancelTransaction error = %@ response= %@", error, response);
    NSString *msg = nil;
    if (!error) msg = [NSString stringWithFormat:@"Successful"];
    else msg = [NSString stringWithFormat:@"UnSuccessful"];
    
    [[[UIAlertView alloc] initWithTitle:@"Transaction Cancel" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self removeController:controller];
}

- (void)didFinishCASTransaction:(PGTransactionViewController *)controller response:(NSDictionary *)response
{
    DEBUGLOG(@"ViewController::didFinishCASTransaction:response = %@", response);
}

@end
