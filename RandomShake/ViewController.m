//
//  ViewController.m
//  RandomShake
//
//  Created by Egor on 2/15/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import "WebPage.h"


// If web page is loaded not because of shake, which means it was already loaded
// and saved to the array, it should not trigger webViewDidFinishLoad: method
// to save this page once more.


@interface ViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate> {

    BOOL loaded;
    BOOL didEdgePan;
    int index;
    NSMutableArray<WebPage*> *webPages;
    
    IBOutlet UIProgressView* myProgressView;
    NSTimer *myTimer;
    __weak IBOutlet UILabel *shakeLabel;
    
    UIView *maskView;
    NSTimer *maskTimer;
    
}

@end

@implementation ViewController

#pragma mark - View setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [myProgressView setProgress:0.0f];
    [_webView setDelegate:self];
    
    // Index of current page in Web Pages array
    index = -1;
    
    webPages = [[NSMutableArray alloc] init];
    
    // Setup left gesture recognizer
    UIScreenEdgePanGestureRecognizer *leftPanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(leftEdgePanGestureRecognizer:)];
    [leftPanGestureRecognizer setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:leftPanGestureRecognizer];
    
    // Setup right gesture recognizer
    UIScreenEdgePanGestureRecognizer *rightPanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(rightEdgePanGestureRecognizer:)];
    [rightPanGestureRecognizer setEdges:UIRectEdgeRight];
    [self.view addGestureRecognizer:rightPanGestureRecognizer];
    
}

- (IBAction)buttonPressed:(id)sender {
    if ([_webView isLoading]) {
        return;
    }
    [_webView setHidden:false];
    [_webView loadRequest:[self randomWikipediaPageRequest]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)canBecomeFirstResponder{
    return true;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}


#pragma mark - Gestures and motion handle

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if ([_webView isLoading]) {
        return;
    }
    if (motion == UIEventSubtypeMotionShake) {
        [_webView setHidden:false];
        [_webView loadRequest:[self randomWikipediaPageRequest]];
    }
}

-(void)leftEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer*)gesture{
   NSLog(@"works from left side");
    
    if (index == -1) {
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        if (maskView) {
            [maskView removeFromSuperview];
        }
        
        maskView = [[UIView alloc] initWithFrame:CGRectZero];
        [maskView setAlpha:0.5];
        
        if (index == 0) { // Cant go back anymore, back swipe color is grey
            [maskView setBackgroundColor:[UIColor darkGrayColor]];
        } else {    // Can go back, back swipe color is blue
            [maskView setBackgroundColor:[UIColor colorWithRed:14.0/255 green:122.0/255 blue:254.0/255 alpha:1.0]];
        }
        [self.view addSubview:maskView];
    }
    if (gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self.view];
        CGRect maskFrame = CGRectMake(0, 0, translation.x * 0.4, self.view.frame.size.height);
        [maskView setFrame:maskFrame];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        maskTimer = [NSTimer scheduledTimerWithTimeInterval:0.01666f target:self selector:@selector(fadeOutMaskView) userInfo:nil repeats:true];
        [maskView setBackgroundColor:[UIColor darkGrayColor]];

        if (index <= 0 || maskView.frame.size.width < 50) {
            return;
        }
        
        index--;

        WebPage *prevPage = [webPages objectAtIndex:index];
        NSURLRequest *request = [NSURLRequest requestWithURL:prevPage.url];
        
        didEdgePan = true;
        [_webView loadRequest:request];

    }
}


-(void)rightEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer*)gesture{
    NSLog(@"works from right side");
   
    if (index == -1) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (maskView) {
            [maskView removeFromSuperview];
        }
        maskView = [[UIView alloc] initWithFrame:CGRectZero];
        [maskView setAlpha:0.5];
        
        if (index == webPages.count - 1) {
            [maskView setBackgroundColor:[UIColor darkGrayColor]];
        } else {
            [maskView setBackgroundColor:[UIColor colorWithRed:14.0/255 green:122.0/255 blue:254.0/255 alpha:1.0]];
        }
        [self.view addSubview:maskView];
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self.view];
        CGFloat xTrans = fabs(translation.x);
        CGRect maskFrame = CGRectMake(self.view.frame.size.width - (xTrans * 0.4), 0, self.view.frame.size.width, self.view.frame.size.height);
        [maskView setFrame:maskFrame];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        maskTimer = [NSTimer scheduledTimerWithTimeInterval:0.01666f target:self selector:@selector(fadeOutMaskView) userInfo:nil repeats:true];
        [maskView setBackgroundColor:[UIColor darkGrayColor]];

        if (maskView.frame.size.width < 50 || index >= webPages.count - 1) {
            return;
        }
        
        index++;
        WebPage *nextPage = [webPages objectAtIndex:index];
        NSURLRequest *request = [NSURLRequest requestWithURL:nextPage.url];
        
        didEdgePan = true;
        [_webView loadRequest:request];
    }
}

-(void)handleScreenEdgePanGesture{
    
}

#pragma mark - Misc

-(NSURLRequest *)randomWikipediaPageRequest{
    NSURL *url = [NSURL URLWithString:@"https://en.m.wikipedia.org/wiki/Special:Random"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return request;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    if (shakeLabel) {
        [shakeLabel removeFromSuperview];
    }
    [myProgressView setHidden:false];
    [myProgressView setProgress:0];
    loaded = false;
    //0.01667 is roughly 1/60, so it will update at 60 FPS
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
    
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    loaded = true;
    
    // If the new Web Page was invoked not by back/forward screen pans,
    // delete all Web Pages after 'index', then add new Web Page to the end
    // of the webPages array
    if (!didEdgePan){
        index++;
        if ([webPages lastObject]) {
            int length = webPages.count;
            for (int i = index; i < length; i++) {
                [webPages removeObjectAtIndex:index];
            }
        }
        
        WebPage *webPage = [[WebPage alloc] init];
        
        // An issue may be there
        [webPage setUrl:_webView.request.URL];
        
        if ([webPages lastObject]) {
            webPage.previous = [webPages objectAtIndex:index-1];
            [[webPages objectAtIndex:index-1] setNext:webPage];
        }
        [webPages addObject:webPage];
    
    }
    didEdgePan = false;
    
}

-(void)timerCallback {
    if (loaded) {
        if (myProgressView.progress >= 1) {
            myProgressView.hidden = true;
            [myTimer invalidate];
        }
        else {
            myProgressView.progress += 0.1;
        }
    }
    else {
        myProgressView.progress += 0.005;
        if (myProgressView.progress >= 0.90) {
            myProgressView.progress = 0.90;
        }
    }
}

-(void) fadeOutMaskView {
    
    if (maskView.alpha > 0) {
        maskView.alpha -= 0.04f;
    }
    else {
        [maskView removeFromSuperview];
        [maskTimer invalidate];
    }
}

@end
