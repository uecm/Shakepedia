//
//  ViewController.m
//  RandomShake
//
//  Created by Egor on 2/15/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import "WebPage.h"


//TODO
// - Make a correct way to navigate through web pages,
//   without unnecessary saves of them to the array
// - Create view transition on gesture pan

// If web page is loaded not because of shake, which means it was already loaded
// and saved to the array, it should not trigger webViewDidFinishLoad: method
// to save this page once more.


@interface ViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate> {

    BOOL loaded;
    NSMutableArray<WebPage*> *webPages;
    
    IBOutlet UIProgressView* myProgressView;
    NSTimer *myTimer;
    __weak IBOutlet UILabel *shakeLabel;
    
}

@end

@implementation ViewController

#pragma mark - View setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [myProgressView setProgress:0.0f];
    [_webView setDelegate:self];
    
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
    if (motion == UIEventSubtypeMotionShake) {
        [_webView setHidden:false];
        [_webView loadRequest:[self randomWikipediaPageRequest]];
    }
}

-(void)leftEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer*)gesture{
   NSLog(@"works from left side");
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if ([_webView canGoBack]) {
            [_webView goBack];
        }
    }
}

-(void)rightEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer*)gesture{
    NSLog(@"works from right side");
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if ([_webView canGoForward]) {
            [_webView goForward];
        }
    }
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
    
    // Create a WebPage and add it to the chained array of WebPages
    // If array already contains a WebPage, link them to each other respectively
    
    WebPage *webPage = [[WebPage alloc] init];
    [webPage setUrl:_webView.request.URL];
    
    if ([webPages lastObject]) {
        webPage.previous = webPages.lastObject;
        [webPages.lastObject setNext:webPage];
    }
    [webPages addObject:webPage];
    
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


@end
