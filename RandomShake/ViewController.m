//
//  ViewController.m
//  RandomShake
//
//  Created by Egor on 2/15/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate> {

    BOOL loaded;
    IBOutlet UIProgressView* myProgressView;
    NSTimer *myTimer;
    __weak IBOutlet UILabel *shakeLabel;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [myProgressView setProgress:0.0f];
    [_webView setDelegate:self];
    // Do any additional setup after loading the view, typically from a nib.
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

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if (motion == UIEventSubtypeMotionShake) {
        [_webView setHidden:false];
        [_webView loadRequest:[self randomWikipediaPageRequest]];
        
    }
}
-(NSURLRequest* )randomWikipediaPageRequest{    
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
