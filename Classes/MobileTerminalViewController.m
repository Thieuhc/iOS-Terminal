// MobileTerminalViewController.m
// MobileTerminal

#import "MobileTerminalViewController.h"

#import "Terminal/TerminalKeyboard.h"
#import "Terminal/TerminalGroupView.h"
#import "Terminal/TerminalView.h"
#import "Preferences/Settings.h"
#import "Preferences/TerminalSettings.h"
#import "VT100/ColorMap.h"
#import "MenuView.h"
#import "GestureResponder.h"
#import "GestureActionRegistry.h"

@implementation MobileTerminalViewController

@synthesize contentView;
@synthesize terminalGroupView;
@synthesize terminalSelector;
@synthesize preferencesButton;
@synthesize menuButton;
@synthesize interfaceDelegate;
@synthesize menuView;
@synthesize gestureResponder;
@synthesize gestureActionRegistry;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (void)awakeFromNib
{
  terminalKeyboard = [[TerminalKeyboard alloc] init];
  keyboardShown = NO;  

  // Copy and paste is off by default
  copyPasteEnabled = NO;
}

- (void)registerForKeyboardNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasHidden:)
                                               name:UIKeyboardDidHideNotification
                                             object:nil];
}

- (void)unregisterForKeyboardNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardDidShowNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardDidHideNotification
                                                object:nil];
}

// TODO(allen): Fix the deprecation of UIKeyboardBoundsUserInfoKey
// below -- it requires more of a change because the replacement
// is not available in 3.1.3

- (void)keyboardWasShown:(NSNotification*)aNotification
{
  if (keyboardShown) {
    return;
  }
  keyboardShown = YES;

  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  
  // Reset the height of the terminal to full screen not shown by the keyboard
  CGRect viewFrame = [contentView frame];
  viewFrame.size.height -= keyboardSize.height;
  contentView.frame = viewFrame;
}

- (void)keyboardWasHidden:(NSNotification*)aNotification
{
  if (!keyboardShown) {
    return;
  }
  keyboardShown = NO;

  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;  
  
  // Resize to the original height of the screen without the keyboard
  CGRect viewFrame = [contentView frame];
  viewFrame.size.height += keyboardSize.height;
  contentView.frame = viewFrame;
}

- (void)setShowKeyboard:(BOOL)showKeyboard
{
  if (showKeyboard) {
    [terminalKeyboard becomeFirstResponder];
  } else {
    [terminalKeyboard resignFirstResponder];
  }
}

- (void)toggleKeyboard:(id)sender
{
  BOOL isShown = keyboardShown;
  [self setShowKeyboard:!isShown];
}

- (void)toggleCopyPaste:(id)sender;
{
  copyPasteEnabled = !copyPasteEnabled;
  [gestureResponder setSwipesEnabled:!copyPasteEnabled];
  for (int i = 0; i < [terminalGroupView terminalCount]; ++i) {
    TerminalView* terminal = [terminalGroupView terminalAtIndex:i];
    [terminal setCopyPasteEnabled:copyPasteEnabled];
  }
}

- (IBAction)ctrl:(UIButton *)sender {
    TerminalKeyboard *keyInput = (TerminalKeyboard *)terminalKeyboard.inputTextField;
    keyInput.controlKeyMode = !keyInput.controlKeyMode;
    sender.selected = keyInput.controlKeyMode;
    [self performSelector:@selector(selectedButton:) withObject:sender afterDelay:3.0];
}

- (void)selectedButton:(UIButton *)button
{
    TerminalKeyboard *keyInput = (TerminalKeyboard *)terminalKeyboard.inputTextField;
    keyInput.controlKeyMode = NO;
    button.selected = NO;
}


- (IBAction)esc:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c",0x1b] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)tab:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c",0x9] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)up:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c%c%c",(char)0x1B,(char)0x5B,(char)0x41] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)down:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c%c%c",(char)0x1B,(char)0x5B,(char)0x42] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)left:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c%c%c",(char)0x1B,(char)0x5B,(char)0x44] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)right:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c%c%c",(char)0x1B,(char)0x5B,(char)0x43] dataUsingEncoding:NSASCIIStringEncoding]];
}

- (IBAction)hidefn:(id)sender {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    [specialscroller setAlpha:1];
    [UIView commitAnimations];
}

- (IBAction)showfn:(id)sender {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    [specialscroller setAlpha:0];
    [UIView commitAnimations];
}

- (IBAction)fn:(UIBarButtonItem *)sender {
    if ([sender.title isEqualToString:@"F1"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%cOP",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F2"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%cOQ",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F3"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%cOR",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F4"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%cOS",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F5"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[15~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F6"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[17~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F7"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[18~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F8"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[19~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F9"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[20~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F10"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[21~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F11"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[22~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([sender.title isEqualToString:@"F12"]){
        [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"%c[23~",0x1B] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (IBAction)pipe:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"|"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)slash:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"/"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)hyphen:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"-"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)bar:(id)sender {
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@"_"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)semiCoron:(id)sender
{
    [[terminalGroupView terminalAtIndex:[terminalSelector currentPage]] receiveKeyboardInput:[[NSString stringWithFormat:@";"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)keyboard:(id)sender {
    BOOL isShown = keyboardShown;
    [self setShowKeyboard:!isShown];
}

// Invoked when the page control is clicked to make a new terminal active.  The
// keyboard events are forwarded to the new active terminal and it is made the
// front-most terminal view.
- (void)terminalSelectionDidChange:(id)sender 
{
  TerminalView* terminalView =
      [terminalGroupView terminalAtIndex:[terminalSelector currentPage]];
  terminalKeyboard.inputDelegate = terminalView;
  gestureActionRegistry.terminalInput = terminalView;
  [terminalGroupView bringTerminalToFront:terminalView];
}

// Invoked when the preferences button is pressed
- (void)preferencesButtonPressed:(id)sender 
{
  // Remember the keyboard state for the next reload and don't listen for
  // keyboard hide/show events
  shouldShowKeyboard = keyboardShown;
  [self unregisterForKeyboardNotifications];

  [interfaceDelegate preferencesButtonPressed];
}

// Invoked when the menu button is pressed
- (void)menuButtonPressed:(id)sender 
{
  [menuView setHidden:![menuView isHidden]];
}

// Invoked when a menu item is clicked, to run the specified command.
- (void)selectedCommand:(NSString*)command
{
  TerminalView* terminalView = [terminalGroupView frontTerminal];
  [terminalView receiveKeyboardInput:[command dataUsingEncoding:NSUTF8StringEncoding]];
  
  // Make the menu disappear
  [menuView setHidden:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // User clicked the Exit button below
  exit(0);
}

- (void)viewDidLoad {
  [super viewDidLoad];

  @try {
    [terminalGroupView startSubProcess];
  } @catch (NSException* e) {
    NSLog(@"Caught %@: %@", [e name], [e reason]);
    if ([[e name] isEqualToString:@"ForkException"]) {
      // This happens if we fail to fork for some reason.
      // TODO(allen): Provide a helpful hint -- a kernel patch?
      UIAlertView* view =
      [[UIAlertView alloc] initWithTitle:[e name]
                                 message:[e reason]
                                delegate:self
                       cancelButtonTitle:@"Exit"
                       otherButtonTitles:NULL];
      [view show];
      return;
    }
    [e raise];
    return;
  }

  // TODO(allen):  This should be configurable
  shouldShowKeyboard = YES;

  // Adding the keyboard to the view has no effect, except that it is will
  // later allow us to make it the first responder so we can show the keyboard
  // on the screen.
  [[self view] addSubview:terminalKeyboard];

  // The menu button points to the right, but for this context it should point
  // up, since the menu moves that way.
  menuButton.transform = CGAffineTransformMakeRotation(-90.0f * M_PI / 180.0f);
  [menuButton setNeedsLayout];
  
   /*CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (![UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && screenSize.height >= 667.0) {
         preferencesButton.frame = CGRectOffset(preferencesButton.frame, -screenSize.width +100.0, 0.0);
     }*/
    
  // Setup the page control that selects the active terminal
  [terminalSelector setNumberOfPages:[terminalGroupView terminalCount]];
  [terminalSelector setCurrentPage:0];
  // Make the first terminal active
  [self terminalSelectionDidChange:self];
    /*
    BOOL isPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    
    CGRect frame = terminalGroupView.frame;
    
    float height = (isPad) ? 300 : 100;
    frame = CGRectMake(frame.origin.x, frame.origin.y, height, frame.size.width);*/
    /*
    CGRect frame = terminalGroupView.frame;
    frame.origin.y += 49;
    frame.size.height -= 49;
    frame.size.height -= 19;
    terminalGroupView.frame = frame;*/
    fnscroller.contentSize = CGSizeMake(600, 43);
    specialscroller.contentSize = CGSizeMake(640, 43);
}

- (void)viewDidAppear:(BOOL)animated
{
  [interfaceDelegate rootViewDidAppear];
  [self registerForKeyboardNotifications];
  [self setShowKeyboard:shouldShowKeyboard];
  
  // Reset the font in case it changed in the preferenes view
  TerminalSettings* settings = [[Settings sharedInstance] terminalSettings];
  UIFont* font = [settings font];
  for (int i = 0; i < [terminalGroupView terminalCount]; ++i) {
    TerminalView* terminalView = [terminalGroupView terminalAtIndex:i];
    [terminalView setFont:font];
    [terminalView setNeedsLayout];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // This supports everything except for upside down, since upside down is most
  // likely accidental.
  switch (interfaceOrientation) {
    case UIInterfaceOrientationPortrait:
    //case UIInterfaceOrientationLandscapeLeft:
    //case UIInterfaceOrientationLandscapeRight:
      return YES;
    default:
      return NO;
  }
}

- (BOOL)shouldAutorotate
{
    //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return YES;
    //} else {
    //   return NO;
    //}
}

- (NSUInteger)supportedInterfaceOrientations
{
    //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    //} else {
     //   return UIInterfaceOrientationMaskPortrait;
    //}
}
/*
//iOS6.0より前
//画面回転に関する制御
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;    //全方位回転
    
    //    if(interfaceOrientation == UIInterfaceOrientationPortrait){
    //        // 通常
    //        return YES;
    //    }else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
    //        // 左に倒した状態
    //        return YES;
    //    }else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
    //        // 右に倒した状態
    //        return YES;
    //    }else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
    //        // 逆さまの状態
    //        return NO;
    //    }
    
}


//iOS6.0以降
//回転処理が存在し、可能かどうか
- (BOOL)shouldAutorotate
{
    return YES; //回転許可
}

//回転する方向の指定
- (NSUInteger)supportedInterfaceOrientations
{
    //全方位回転
    return UIInterfaceOrientationMaskAll;
    ////Portrait(HomeButtonが下)のみ
    //      return UIInterfaceOrientationMaskPortrait;
    ////LandscapeLeft(HomeButtonが右)のみ
    //      return UIInterfaceOrientationMaskLandscapeLeft;
    ////LandscapeRight(HomeButtonが左)のみ
    //      return UIInterfaceOrientationMaskLandscapeRight;
    ////PortraitUpsideDown(HomeButtonが上)のみ
    //      return UIInterfaceOrientationMaskPortraitUpsideDown;
    ////UpsideDown(HomeButtonが上)以外回転
    //  return UIInterfaceOrientationMaskAllButUpsideDown;
    ////横のみ回転
    //      return UIInterfaceOrientationMaskLandscape;
}
*/
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // We rotated, and almost certainly changed the frame size of the text view.
    [[self view] layoutSubviews];
}

- (void)didReceiveMemoryWarning {
	// TODO(allen): Should clear scrollback buffers to save memory? 
  [super didReceiveMemoryWarning];
}

- (void)dealloc {
  [terminalKeyboard release];
  [super dealloc];
}

@end
