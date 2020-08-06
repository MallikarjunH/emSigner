//
//  CoSignPendingListVC.m
//  emSigner
//
//  Created by Nawin Kumar on 12/4/16.
//  Copyright © 2016 Emudhra. All rights reserved.
//

#import "CoSignPendingListVC.h"
#import "WebserviceManager.h"
#import "HoursConstants.h"
#import "NSObject+Activity.h"
#import "MBProgressHUD.h"
#import "ShareVC.h"
#import "UITextView+Placeholder.h"
#import "LMNavigationController.h"
#import "RecallVC.h"
#import "AppDelegate.h"
#import "CustomPopOverVC.h"
#import "CommentsController.h"
#import "ViewController.h"

@interface CoSignPendingListVC ()<CellPopUp>
{
    CustomPopOverVC *popVC;
    int yPosition;
}

@property (nonatomic, strong) UITextView *shareTextView;
@property (nonatomic, strong) UITextView *declineTextView;
@end

@implementation CoSignPendingListVC


NSString *key;
NSString *_filePath;
BOOL reflowMode;
UIScrollView *canvasScrollView;
UIBarButtonItem *backButton;
int barmode;
int searchPage;
int cancelSearch;
int showLinks;
int width; // current screen size
int height;
int current; // currently visible page
int scroll_animating; // stop view updates during scrolling animations
float scale; // scale applied to views (only used in reflow mode)
BOOL _isRotating;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _addFile = [[NSMutableArray alloc] init];
  
    NSLog(@"%@",_pathForDoc);
    self.signatorylbl.text = _signatoryString;

    UIButton* customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setImage:[UIImage imageNamed:@"three-aligned-squares-in-vertical-line"] forState:UIControlStateNormal];
    self.waitingForOthersTabBar.delegate = self;
    
    [_signatorylbl sizeToFit];
    
    if (self.signatoryString != nil) {
        self.signatorylbl.text =[NSString stringWithFormat:@"%@",self.signatoryString];
    }
    
    customButton.frame = CGRectMake(0, 0, 25, 25);
//    UIBarButtonItem* customBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
//    [customButton addTarget:self
//                     action:@selector(flipView:)
//           forControlEvents:UIControlEventTouchUpInside];
//
//    self.navigationItem.rightBarButtonItem = customBarButtonItem;
   
    UIButton* customButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton1 setImage:[UIImage imageNamed:@"ico-back-24.png"] forState:UIControlStateNormal];
  
    [customButton1 sizeToFit];
    UIBarButtonItem* customBarButtonItem1 = [[UIBarButtonItem alloc] initWithCustomView:customButton1];
    [customButton1 addTarget:self
                      action:@selector(popViewControllerAnimated:)
            forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = customBarButtonItem1;
    
//    if ([_documentCount intValue] > 1) {
        customButton.hidden = NO;
//    }
//    else if ([_attachmentCount intValue] > 0)
//    {
//        customButton.hidden = NO;
//    }
//    else{
//        customButton.hidden = YES;
//    }

}

- (void) viewWillLayoutSubviews
{

}

- (void) viewDidAppear: (BOOL)animated
{
    [super viewDidAppear:animated];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.pdfView animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = [NSString stringWithFormat:@"Page %@ of %lu", self.pdfView.currentPage.label, (unsigned long)self.pdfDocument.pageCount];
    hud.margin = 10.f;
    hud.yOffset = 170;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:1];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewAnnotationHitNotification object:self.pdfView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewPageChangedNotification object:self.pdfView];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    current=0;
    self.title = _myTitle;
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    
    [self preparePDFViewWithPageMode:kPDFDisplaySinglePage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFViewAnnotationHitNotification:) name:PDFViewAnnotationHitNotification object:self.pdfView];
    
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFViewPageChangedNotification:) name:PDFViewPageChangedNotification object:self.pdfView];
}


- (void)preparePDFViewWithPageMode:(PDFDisplayMode) displayMode {
    
    NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImagedetail options:0];
    
    self.pdfDocument = [[PDFDocument alloc] initWithData:data];
    if (self.passwordForPDF) {
        
        [self.pdfDocument unlockWithPassword:[[NSUserDefaults standardUserDefaults] valueForKey:@"Password"]];
        
    }
    
    self.pdfView.displaysPageBreaks = NO;
    self.pdfView.autoScales = YES;
    self.pdfView.maxScaleFactor = 4.0;
    self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit;
    
    //load the document
    self.pdfView.document = self.pdfDocument;
    
    //set the display mode
    self.pdfView.displayMode = displayMode;
    
    self.pdfView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.pdfView.displayDirection = kPDFDisplayDirectionHorizontal;
    [self.pdfView zoomIn:self];
    self.pdfView.autoScales = true;
    self.pdfView.backgroundColor = [UIColor  whiteColor];
    
    
    self.pdfView.document = self.pdfDocument;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect signatureFieldBounds = CGRectMake(300, 350, 100, 30);
    [self.pdfView usePageViewController:(displayMode == kPDFDisplaySinglePage) ? YES :NO withViewOptions:nil];
    
}


-(void)flipView//:(UIButton*)sender
{
    
    UIAlertController * view=   [[UIAlertController
                                     alloc]init];
    
       UIAlertAction* Document = [UIAlertAction
                                actionWithTitle:@"Documents "
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    //tag = 0;
                                    [self dissmissCellPopup:0];
                                    
                                }];
        UIAlertAction* attachment  = [UIAlertAction
                                   actionWithTitle:@"View/Add Attachments"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                        //tag = 1;
                                       [self dissmissCellPopup:1];

                                   }];
    UIAlertAction* cancel = [UIAlertAction
                                actionWithTitle:@"Cancel"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    
                                }];
    
    if ([_documentCount intValue] > 1){
        [view addAction:Document];
    }
        [view addAction:attachment];
        [view addAction:cancel];
       
       [self presentViewController:view animated:YES completion:nil];
       
    
//    if ([_documentCount isEqualToString:@"1"] && _attachmentCount > 0) {
//        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        popVC = [newStoryBoard instantiateViewControllerWithIdentifier:@"CustomPopOverVC"];
//        UINavigationController *popNav = [[UINavigationController alloc]initWithRootViewController: popVC];
//        popVC.delegate = self;
//        popVC.preferredContentSize = CGSizeMake(200,8);
//        popVC.attachmentCount = _attachmentCount;
//        popVC.documentCount = _documentCount;
//        popVC.workflowID =_workflowID;
//        popNav.modalPresentationStyle = UIModalPresentationPopover;
//        _popover = popNav.popoverPresentationController;
//        _popover.delegate = self;
//        _popover.sourceView = self.view;
//        CGRect frame = [sender frame];
//       // frame.origin.y = frame.origin.y+10;
//        frame.origin.y = self.view.frame.origin.y - frame.size.height + 40;
//        frame.origin.x =  self.view.frame.size.width - frame.size.width +20;
//        //set the position of PopoverView(you can change it according to your requirement.)
//        _popover.sourceRect = frame;
//        popNav.navigationBarHidden = YES;
//        [self presentViewController: popNav animated:YES completion:nil];
//
//    }
//
//    else{
//        if ([_attachmentCount  intValue]>0) {
//            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            popVC = [newStoryBoard instantiateViewControllerWithIdentifier:@"CustomPopOverVC"];
//            UINavigationController *popNav = [[UINavigationController alloc]initWithRootViewController: popVC];
//            popVC.delegate = self;
//            popVC.preferredContentSize = CGSizeMake(200,60);
//            popVC.attachmentCount = _attachmentCount;
//            popVC.documentCount = _documentCount;
//            popVC.workflowID =_workflowID;
//            popNav.modalPresentationStyle = UIModalPresentationPopover;
//            _popover = popNav.popoverPresentationController;
//            _popover.delegate = self;
//            _popover.sourceView = self.view;
//            CGRect frame = [sender frame];
//            frame.origin.y = self.view.frame.origin.y - frame.size.height + 40;
//            frame.origin.x =  self.view.frame.size.width - frame.size.width +20;
//            _popover.sourceRect = frame;
//            popNav.navigationBarHidden = YES;
//            [self presentViewController: popNav animated:YES completion:nil];
//
//        }
//        else{
//            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            popVC = [newStoryBoard instantiateViewControllerWithIdentifier:@"CustomPopOverVC"];
//            UINavigationController *popNav = [[UINavigationController alloc]initWithRootViewController: popVC];
//            popVC.delegate = self;
//            popVC.preferredContentSize = CGSizeMake(200,8);
//            popVC.attachmentCount = _attachmentCount;
//            popVC.documentCount = _documentCount;
//            popVC.workflowID =_workflowID;
//            popNav.modalPresentationStyle = UIModalPresentationPopover;
//            _popover = popNav.popoverPresentationController;
//            _popover.delegate = self;
//            _popover.sourceView = self.view;
//            CGRect frame = [sender frame];
//            frame.origin.y = self.view.frame.origin.y - frame.size.height + 40 ;
//            frame.origin.x =  self.view.frame.size.width - frame.size.width +20;
//            _popover.sourceRect = frame;
//            popNav.navigationBarHidden = YES;
//            [self presentViewController: popNav animated:YES completion:nil];
//
//        }
//
//    }
    
}

-(void)dissmissCellPopup:(NSInteger)row{
    switch (row) {
        case 0:
        {
            [self dismissViewControllerAnimated:NO completion:nil];
            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            InprogressMultiplePdf *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"InprogressMultiplePdf"];
            objTrackOrderVC.delegate = self;
            objTrackOrderVC.workFlowId = _workflowID;
            objTrackOrderVC.workFlowType = _workFlowType;
            objTrackOrderVC.currentSelectedRow = _selectedIndex;
            objTrackOrderVC.strExcutedFrom = _strExcutedFrom;
            objTrackOrderVC.document = @"Documents";
            [self.navigationController pushViewController:objTrackOrderVC animated:YES];
        }
            
            break;
        case 1:
        {
            [self dismissViewControllerAnimated:NO completion:nil];
            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            AttachedVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"AttachedVC"];
            objTrackOrderVC.workFlowId = _workflowID;
                       objTrackOrderVC.documentID = _documentID;
                       objTrackOrderVC.documentName = _myTitle;
                       objTrackOrderVC.base64Image = _pdfImagedetail;
                       objTrackOrderVC.currentSelectedRow = _selectedIndex;
                       objTrackOrderVC.document = @"Attached Documents";
                       objTrackOrderVC.isAttached = true;
                       objTrackOrderVC.isDocStore = true;
                       objTrackOrderVC.isFromWF = @"N";
            objTrackOrderVC.document = @"Attached Documents";
            UINavigationController *objNavigationController = [[UINavigationController alloc]initWithRootViewController:objTrackOrderVC];
            [self presentViewController:objNavigationController animated:true completion:nil];
            //[self.navigationController pushViewController:objTrackOrderVC animated:YES];
        }
            
            break;
            
            
        default:
            break;
    }
    
}


#pragma mark == UIPopoverPresentationControllerDelegate ==
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}


-(void)dataFromControllerOne:(NSString *)data
{
    _multiplePdfImagedetail=data;
}

-(void)documentnameControllerOne:(NSString *)dname
{
    _myTitle=dname;
}

-(void)dataForWorkflowId:(NSString *)dWorkflowid
{
    _documentID = dWorkflowid;
}

-(void)selectedCellIndexOne:(int)iIndex
{
    _selectedIndex = iIndex;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
     if (alertView.tag == 1)
    {
        if (buttonIndex == 0)
        {
           if ([self.declineTextView text].length > 1)
           {
              
               [self startActivity:@"Processing..."];
               
               NSString *post = [NSString stringWithFormat:@"WorkflowId=%@&Remarks=%@",_workflowID,[self.declineTextView text]];
               [WebserviceManager sendSyncRequestWithURL:kDecline method:SAServiceReqestHTTPMethodPOST body:post completionBlock:^(BOOL status, id responseValue)
                {
                    
                   // if(status)
                        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])

                    {
                        dispatch_async(dispatch_get_main_queue(),
                                       ^{
                                           
                                           _declineArray = responseValue;
                                           /*******************/
                                           UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                           LMNavigationController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"HomeNavController"];
                                           [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                                           //
                                           UIAlertView *alertView31 = [[UIAlertView alloc] initWithTitle:@""
                                                                                                 message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                                                delegate:self
                                                                                       cancelButtonTitle:@"OK"
                                                                                       otherButtonTitles:nil, nil];
                                           alertView31.tag = 31;
                                           [alertView31 show];
                                           //[_pendingTableView reloadData];
                                           
                                           
                                           [self stopActivity];
                                       });
                        
                    }
                    else{
                        // if ([responseValue isKindOfClass:[NSString class]]) {
                        // if ([responseValue isEqualToString:@"Invalid token Please Contact Adminstrator"]) {
                        
                        [self stopActivity];
                        UIAlertController * alert = [UIAlertController
                                                     alertControllerWithTitle:nil
                                                     message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0]
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        //Add Buttons
                        
                        UIAlertAction* yesButton = [UIAlertAction
                                                    actionWithTitle:@"Ok"
                                                    style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        //Handle your yes please button action here
                                                        //Logout
                                                        AppDelegate *theDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                                                        theDelegate.isLoggedIn = NO;
                                                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:theDelegate.isLoggedIn] forKey:@"isLogin"];
                                                        [NSUserDefaults resetStandardUserDefaults];
                                                        [NSUserDefaults standardUserDefaults];
                                                        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                                        ViewController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ViewController"];
                                                        [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                                                    }];
                        
                        [alert addAction:yesButton];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                        return;
                    }
                    
                }];
               
            
           }
            
           else
           {
               UIAlertView *ErrorAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:@"Please Add Remarks" delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
               [ErrorAlert show];
           }
        }
        else if (buttonIndex == 0)
        {
            
        }
    }
    
    /*****************************Download**************************************/
    
    else if (alertView.tag == 3)
    {
        if (buttonIndex == 0)
        {
            
            
            [self startActivity:@"Loading..."];
            
            NSString *requestURL = [NSString stringWithFormat:@"%@DownloadWorkflowDocuments?WorkFlowId=%@",kDownloadPdf,_workflowID];
            [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
                
                
                
             //   if(status)
                    if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])

                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        _pdfImageArray=[responseValue valueForKey:@"Response"];
                        if (_pdfImageArray != (id)[NSNull null])
                        {
                            [_addFile removeAllObjects];
                            for(int i=0; i<[_pdfImageArray count];i++)
                            {
                                
                                _pdfFileName = [[_pdfImageArray objectAtIndex:i] objectForKey:@"DocumentName"];
                                _pdfFiledata = [[_pdfImageArray objectAtIndex:i] objectForKey:@"Document"];
                                
                                NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfFiledata options:0];
                                NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
                                CFUUIDRef uuid = CFUUIDCreate(NULL);
                                CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                                CFRelease(uuid);
                                NSString *uniqueFileName = [NSString stringWithFormat:@"%@%@%@%@",_pdfFileName,@"                                                 ",(__bridge NSString *)uuidString, _pdfFileName];
                                
                                
                                NSString *path = [documentsDirectory stringByAppendingPathComponent:uniqueFileName];
                                [_addFile addObject:path];
                                
                                [data writeToFile:path atomically:YES];
                                
                                /*check already exist document*/
                                
                                
                                //                             NSFileManager *fileManager = [NSFileManager defaultManager];
                                //                             if ([fileManager fileExistsAtPath:path]){
                                //                                int i = 1;
                                //                                 NSString *testString= _pdfFileName;
                                //                                 NSArray *array = [testString componentsSeparatedByString:@"."];
                                //                                 NSString *name = [array objectAtIndex:0];
                                //                                 NSString *path1 = [NSString stringWithFormat:@"%@%@%d", name,@"_", i];
                                //                                 i++;
                                //                                 //path = [path1 stringByAppendingPathExtension:@"pdf"];
                                //
                                //                                 path = [documentsDirectory stringByAppendingPathComponent:[path1 stringByAppendingPathExtension:@"pdf"]];
                                //                                 [data writeToFile:path atomically:YES];
                                //
                                //                             }
                                //                             else{
                                //                                 //NSString *path = [documentsDirectory stringByAppendingPathComponent:_pdfFileName];
                                //                                 [data writeToFile:path atomically:YES];
                                //                             }
                                
                                
                                
                                
                                if (i==_pdfImageArray.count-1)
                                {
                                    [self stopActivity];
                                    QLPreviewController *previewController=[[QLPreviewController alloc]init];
                                    previewController.delegate=self;
                                    previewController.dataSource=self;
                                    [self presentViewController:previewController animated:YES completion:nil];
                                    [previewController.navigationItem setRightBarButtonItem:nil];
                                }
                                
                            }
                            
                        }
                        else{
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                            [alert show];
                        }
                        
                        
                        
                        
                    });
                    
                }
                else{
                    
                    
                }
                
            }];
            
            
        }
        else if (buttonIndex == 1)
        {
            
        }
    }
    /****************************Open Downloaded file*******************************/
//    else if (alertView.tag == 28)
//    {
//        if (buttonIndex == 0)
//        {
//            //currentPreviewIndex=[(UIButton *)sender tag]-1;
//            
//            QLPreviewController *previewController=[[QLPreviewController alloc]init];
//            previewController.delegate=self;
//            previewController.dataSource=self;
//            [self presentViewController:previewController animated:YES completion:nil];
//            [previewController.navigationItem setRightBarButtonItem:nil];
//        }
//        
//    }
    /******************************************************************************/
    
}

//- (void)textViewDidBeginEditing:(UITextView *)textView
//{
//    if ([textView.text isEqualToString:@"Remarks"]) {
//        textView.text = @"";
//        textView.textColor = [UIColor lightGrayColor]; //optional
//    }
////    else if ([textView.text isEqualToString:@"Email (Use a semicolon(;) to add multiple email)"])
////    {
////        textView.text = @"";
////        textView.textColor = [UIColor lightGrayColor];
////    }
//    [textView becomeFirstResponder];
//}

-(void)popViewControllerAnimated:(UIButton*)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)recallBtn
{
    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RecallVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"RecallVC"];
    self.definesPresentationContext = YES; //self is presenting view controller
    //objTrackOrderVC.view.backgroundColor = [UIColor clearColor];
    objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    //    objTrackOrderVC.documentName = [[NSUserDefaults standardUserDefaults]
    //                                    valueForKey:@"PendingDisplayName"];
    objTrackOrderVC.workflowID = _workflowID;
    objTrackOrderVC.strExcutedFrom=@"WaitingForOther";
    [self.navigationController presentViewController:objTrackOrderVC animated:YES completion:nil];
    
}

- (IBAction)downloadBtn:(id)sender
{
//    UIAlertView *alertView3 = [[UIAlertView alloc] initWithTitle:@"Download Document"
//                                                         message:@"Do you want to download document?"
//                                                        delegate:self
//                                               cancelButtonTitle:@"Yes"
//                                               otherButtonTitles:@"No", nil];
//    alertView3.tag = 3;
//    [alertView3 show];

    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RecallVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"RecallVC"];
    self.definesPresentationContext = YES; //self is presenting view controller
    objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    objTrackOrderVC.workflowID = _workflowID;
    objTrackOrderVC.strExcutedFrom=@"WaitingForOther";
    [self.navigationController presentViewController:objTrackOrderVC animated:YES completion:nil];

}

- (void)MoreBtn
{
    
    UIAlertController * view = [[UIAlertController
                                 alloc]init];
    
    UIAlertAction* DocLog = [UIAlertAction
                             actionWithTitle:@"Document Log"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                 DocumentLogVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DocumentLogVC"];
                                 
                                 objTrackOrderVC.workflowID = _workflowID;//[[_pdfImageArray objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];
                                 [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                             }];
    
    UIAlertAction* Download = [UIAlertAction
                               actionWithTitle:@"Download Document"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   
                                   UIAlertController * alert = [UIAlertController
                                                                alertControllerWithTitle:@"Download"
                                                                message:@"Do you want to download document?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
                                   
                                   //Add Buttons
                                   
                                   UIAlertAction* yesButton = [UIAlertAction
                                                               actionWithTitle:@"Yes"
                                                               style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action)
                                                               {
                                                                                                  [self startActivity:@"Loading..."];
                                                                                                  NSString *requestURL = [NSString stringWithFormat:@"%@DownloadWorkflowDocuments?WorkFlowId=%@",kDownloadPdf,_workflowID];
                                                                                                  [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {

                                                                                                     // if(status)
                                                                                                          if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])

                                                                                                      {
                                                                                                          dispatch_async(dispatch_get_main_queue(), ^{

                                                                                                              _pdfImageArray=[responseValue valueForKey:@"Response"];
                                                                                                              if (_pdfImageArray != (id)[NSNull null])
                                                                                                              {
                                                                                                                  [_addFile removeAllObjects];
                                                                                                                  for(int i=0; i<[_pdfImageArray count];i++)
                                                                                                                  {

                                                                                                                      _pdfFileName = [[_pdfImageArray objectAtIndex:i] objectForKey:@"DocumentName"];
                                                                                                                      _pdfFiledata = [[_pdfImageArray objectAtIndex:i] objectForKey:@"Document"];

                                                                                                                      NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfFiledata options:0];
                                                                                                                      NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
                                                                                                                      CFUUIDRef uuid = CFUUIDCreate(NULL);
                                                                                                                      CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                                                                                                                      CFRelease(uuid);
                                                                                                                      NSString *uniqueFileName = [NSString stringWithFormat:@"%@%@%@%@",_pdfFileName,@"                                                 ",(__bridge NSString *)uuidString, _pdfFileName];


                                                                                                                      NSString *path = [documentsDirectory stringByAppendingPathComponent:uniqueFileName];
                                                                                                                      [_addFile addObject:path];

                                                                                                                      [data writeToFile:path atomically:YES];


                                                                                                                      if (i==_pdfImageArray.count-1)
                                                                                                                      {
                                                                                                                          [self stopActivity];
                                                                                                                          QLPreviewController *previewController=[[QLPreviewController alloc]init];
                                                                                                                          previewController.delegate=self;
                                                                                                                          previewController.dataSource=self;
                                                                                                                          [self presentViewController:previewController animated:YES completion:nil];
                                                                                                                          [previewController.navigationItem setRightBarButtonItem:nil];
                                                                                                                      }

                                                                                                                  }

                                                                                                              }
                                                                                                              else{
                                                                                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                                                                                                  [alert show];
                                                                                                              }

                                                                                                          });

                                                                                                      }
                                                                                                      else{

                                                                                                      }
                                       
                                                                                                  }];
                                                               }];
                                                               
                                                                   UIAlertAction* noButton = [UIAlertAction
                                                                                              actionWithTitle:@"No"
                                                                                              style:UIAlertActionStyleDefault
                                                                                              handler:^(UIAlertAction * action) {
                                                                                                  //Handle no, thanks button
                                                                                              }];
                                                                   
                                                                   //Add your buttons to alert controller
                                                                   
                                                                   [alert addAction:yesButton];
                                                                   [alert addAction:noButton];
                                                                   [self presentViewController:alert animated:YES completion:nil];

                               }];
    UIAlertAction* Share = [UIAlertAction
                            actionWithTitle:@"Share Document"
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                
                                //NSString *pendingdocumentName =[[_pdfImageArray objectAtIndex:sender.tag] valueForKey:@"DocumentName"];
                                NSString *pendingWorkflowID =_workflowID;//[[_pdfImageArray objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];
                                UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                ShareVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ShareVC"];
                                objTrackOrderVC.documentName = _myTitle;
                                objTrackOrderVC.workflowID = pendingWorkflowID;
                                [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                                
                            }];
    
    UIAlertAction* Comments = [UIAlertAction
                               actionWithTitle:@"Comments"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                   CommentsController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"CommentsController"];
                                   
                                   objTrackOrderVC.workflowID = _workflowID;
                                   [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                               }];
    
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"cancel"
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action)
                             {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [DocLog setValue:[[UIImage imageNamed:@"stack-exchange.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Download setValue:[[UIImage imageNamed:@"download.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Share setValue:[[UIImage imageNamed:@"share-variant.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Comments setValue:[[UIImage imageNamed:@"comments"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];

    [DocLog setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Download setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Share setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Comments setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];

    view.view.tintColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
  
    [view addAction:DocLog];
    [view addAction:Download];
    [view addAction:Share];
    [view addAction:Comments];

    [view addAction:cancel];

    [self presentViewController:view animated:YES completion:nil];
    
}


- (void)inActiveBtn{
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Do you want to mark document as inactive?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    [self startActivity:@"Processing..."];
                                    NSString *requestURL = [NSString stringWithFormat:@"%@MarkAsInactive?documentId=%@&status=%@",kInactive,_workflowID,@"Pending"];
                                    
                                    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
                                        
                                        //if(status)
                                            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])

                                        {
                                            dispatch_async(dispatch_get_main_queue(),
                                                           ^{
                                                               
                                                               
                                                               _inactiveArray =responseValue;
                                                               /*******************/
                                                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                                                                   message:@"Document got inactive successfully"
                                                                                                                  delegate:self
                                                                                                         cancelButtonTitle:@"OK"
                                                                                                         otherButtonTitles:nil, nil];
                                                               [alertView show];                                                               [self.navigationController popToRootViewControllerAnimated:YES];
                                                               //alertView.delegate = self;
                                                              // [self.navigationController popToRootViewControllerAnimated:YES];
                                                               [self stopActivity];
                                                               
                                                               
                                                           });
                                            
                                        }
                                        else{
                                            
                                            
                                        }
                                        
                                    }];
                                }];
    [alert addAction:yesButton];
    //Add your buttons to alert controller
    
    
    UIAlertAction* noButton = [UIAlertAction
                                actionWithTitle:@"No"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    
                                }];
    
    //Add your buttons to alert controller
    
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)docLogBtn:(id)sender {
    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DocumentLogVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DocumentLogVC"];
    objTrackOrderVC.workflowID = _workflowID ;
    [self.navigationController pushViewController:objTrackOrderVC animated:YES];

}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {

    if (item.tag == 0){
      // decline
        [self inActiveBtn];
    }
    else if (item.tag == 1){
        [self recallBtn];
    }
    else if (item.tag == 2){
        [self flipView];
    }
    else if (item.tag == 3){
           [self MoreBtn];
    }
   
}


-(void)PDFViewPageChangedNotification:(NSNotification*)notification{
    
    NSLog(@"%@",[NSString stringWithFormat:@"Page %@ of %lu", self.pdfView.currentPage.label, (unsigned long)self.pdfDocument.pageCount]);
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.pdfView animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = [NSString stringWithFormat:@"Page %@ of %lu", self.pdfView.currentPage.label, (unsigned long)self.pdfDocument.pageCount];
    hud.margin = 10.f;
    hud.yOffset = 170;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:2];
    
}




#pragma mark - data source(Preview)
//Data source methods
//– numberOfPreviewItemsInPreviewController:
//– previewController:previewItemAtIndex:
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
  return [_addFile count];

}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
//    NSString *path = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path];
//    //You'll need an additional '/'
//    NSString *fileName = [self.pdfImageArray[index] valueForKey:@"DocumentName"];
    NSString *fileName = [_addFile objectAtIndex:index];
    //NSString *fullPath = [path stringByAppendingFormat:@"/%@", fileName];
    return [NSURL fileURLWithPath:fileName];
}

#pragma mark - delegate methods


- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item
{
    return YES;
}

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView **)view
{
    
    //Rectangle of the button which has been pressed by the user
    //Zoom in and out effect appears to happen from the button which is pressed.
    UIView *view1 = [self.view viewWithTag:currentPreviewIndex+1];
    return view1.frame;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
