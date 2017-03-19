//
//  ViewController.m
//  RandomShake
//
//  Created by Egor on 2/15/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import "WebPage.h"


@interface ViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource> {

    BOOL loaded;
    BOOL didEdgePan;
    int index;
    NSMutableArray<WebPage*> *webPages;
    
    IBOutlet UIProgressView* progressView;
    NSTimer *progressTimer;
    
    __weak IBOutlet UILabel *shakeLabel;
    __weak IBOutlet UIButton *languageButton;
    __weak IBOutlet UIPickerView *languagePicker;
    __weak IBOutlet UIButton *doneButton;

    UIView *maskView;
    NSTimer *maskTimer;
    
    NSArray *languages;
    NSArray *langPrefixes;
    NSString *prefix;
}

@end

@implementation ViewController



#pragma mark - View setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    // Do any additional setup after loading the view, typically from a nib.
    [progressView setProgress:0.0f];
    [_webView setDelegate:self];
    
    // Get all Wikipedia supported languages, stored in file 'Languages'
    [self parseLanguagesFromFile];

    // Retrieve user-selected language and set prefix variable accordingly
    NSString *userLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"user_language"];
    prefix = [langPrefixes objectAtIndex:[userLanguage intValue]];
    
    // Color of wikipedia header, use as background for views
    UIColor *backgroundColor = [UIColor colorWithRed:235.0f/255.0f green:236.0f/255.0f blue:240.0f/255.0f alpha:1.0f];
    [self.view setBackgroundColor:backgroundColor];
    [_webView setBackgroundColor:backgroundColor];
    [_webView.scrollView setBackgroundColor:backgroundColor];
    
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
    
    // Add refresh subview
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshPage:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setBackgroundColor:backgroundColor];
    NSMutableAttributedString *refreshTitle = [[NSMutableAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refreshTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HoeflerText-Regular" size:17.0f ] range:NSMakeRange(0, [refreshTitle.string length])];
    [refreshControl setAttributedTitle:refreshTitle];
    
    [self.webView.scrollView addSubview:refreshControl];
    
    // Change status bar color
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = backgroundColor;
    }
    
    // Language picker setup
    [languagePicker setDataSource:self];
    [languagePicker setDelegate:self];
    languagePicker.layer.borderColor = [UIColor lightGrayColor].CGColor;
    languagePicker.layer.borderWidth = 1.0f;
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

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (languages == nil) {
        return 0;
    }
    return languages.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (languages == nil) {
        return @"";
    }
    return languages[row];
}


#pragma mark - Gestures and motion handle

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if ([_webView isLoading]) {
        return;
    }
    if (motion == UIEventSubtypeMotionShake && languagePicker.isHidden) {
        
        [languageButton setHidden:true];
        [_webView setHidden:false];
        [_webView loadRequest:[self randomWikipediaPageRequest]];
    }
}
-(void)leftEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer*)gesture{
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

- (IBAction)languageButtonPressed:(id)sender {
    
    [languagePicker reloadAllComponents];
    [languagePicker setHidden:false];
    [doneButton setHidden:false];
    [shakeLabel setHidden:true];
    
    [languagePicker selectRow:6 inComponent:0 animated:0];
    [languagePicker reloadInputViews];

}

- (IBAction)doneButtonPressed:(id)sender {
    [doneButton setHidden:true];
    [languagePicker setHidden:true];
    [shakeLabel setHidden:false];
    
    NSString *selectedLanguage = [languages objectAtIndex:[languagePicker selectedRowInComponent:0]];
    prefix = [langPrefixes objectAtIndex:[languagePicker selectedRowInComponent:0]];
    [languageButton setTitle:selectedLanguage forState:UIControlStateNormal];
}


#pragma mark - Misc

-(NSURLRequest *)randomWikipediaPageRequest{
    
    NSString *URLString = @"https://en.m.wikipedia.org/wiki/Special:Random";
    
    if (prefix) {
        URLString = [NSString stringWithFormat:@"https://%@.m.wikipedia.org/wiki/Special:Random", prefix];
    }
    NSURL *url = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return request;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    if (shakeLabel) {
        [shakeLabel removeFromSuperview];
    }
    [progressView setHidden:false];
    [progressView setProgress:0];
    loaded = false;
    //0.01667 is roughly 1/60, so it will update at 60 FPS
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    loaded = true;
    
    // If the new Web Page was invoked not by back/forward screen pans,
    // delete all Web Pages after 'index', then add new Web Page to the end
    // of the webPages array
    if (!didEdgePan){
        index++;
        if ([webPages lastObject]) {
            int length = (int)webPages.count;
            for (int i = index; i < length; i++) {
                [webPages removeObjectAtIndex:index];
            }
        }
        WebPage *webPage = [[WebPage alloc] init];
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
        if (progressView.progress >= 1) {
            progressView.hidden = true;
            [progressTimer invalidate];
        }
        else {
            progressView.progress += 0.1;
        }
    }
    else {
        progressView.progress += 0.005;
        if (progressView.progress >= 0.90) {
            progressView.progress = 0.90;
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

-(void) refreshPage:(UIRefreshControl*) refresh{
    [self.webView reload];
    // Actually no edge pan gestrue was made when this code is called,
    // bringing it to true will cause a page not to save once again to the queue.
    didEdgePan = true;
    [refresh endRefreshing];
}

-(void) parseLanguagesFromFile{
    
    //Parsing languages, that wikipedia supports from file.
    //Languages list is stored in 'languages' array,
    //Website prefixes list is stored in 'langPrefixes' array.
    
    NSError *error;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Languages" ofType:nil];
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    NSArray *allStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray *plainLangs = [[NSMutableArray alloc] init];
    NSMutableArray *prefixes = [[NSMutableArray alloc] init];
    
    for (NSString *lang in allStrings) {
        
        // Parse plain language from the line
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\|.[^\\|]*\\}\\}" options:0 error:&error];
        NSRange range = [regex rangeOfFirstMatchInString:lang options:0 range:NSMakeRange(0, [lang length])];
        
        NSString *plainLanguage = [lang substringWithRange:NSMakeRange(range.location+1, range.length-3)];
        [plainLangs addObject:plainLanguage];
        
        // Parse its prefix
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\{\\{.[^\\|]*\\|" options:0 error:&error];
        range = [regex rangeOfFirstMatchInString:lang options:0 range:NSMakeRange(0, [lang length])];
        
        NSString *prefixString = [lang substringWithRange:NSMakeRange(range.location + 2, range.length - 3)];
        [prefixes addObject:prefixString];
    }
    
    languages = plainLangs;
    langPrefixes = prefixes;
}

@end
