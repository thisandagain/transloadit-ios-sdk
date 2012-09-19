#import "IphoneSdkViewController.h"
#import "Config.h"

@implementation IphoneSdkViewController

#pragma mark - View lifecycle

- (void) viewDidLoad
{
	[self.button setTitle:NSLocalizedString(@"Select File", @"") forState:UIControlStateNormal];
    
	if ([TransloaditKey length] == 0 || [TransloaditSecret length] == 0 || [TransloaditTemplateId length] == 0) {
		UIAlertView *error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bad config", @"") message:NSLocalizedString(@"Please edit the Config.h file and insert your transloadit credentials.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil];
		[error show];
	}
}

#pragma mark helpers

- (void)startUpload:(NSDictionary *)info
{
	self.spinner.hidden = YES;
	self.progressBar.hidden = NO;
	self.status.text = NSLocalizedString(@"preparing upload", @"");

    TransloaditRequest *transloadit = [[TransloaditRequest alloc] initWithCredentials:TransloaditKey secret:TransloaditSecret];
    NSData *data = UIImageJPEGRepresentation([UIImage imageNamed:@"logo.jpg"], 0.9f);
    
    [transloadit processData:data withFileName:@"awesomepants.jpg" contentType:@"image/jpg" template:TransloaditTemplateId success:^(id request) {
        NSLog(@"This shit worked!");
    } failure:^(id request, NSError *error) {
        NSLog(@"Shit is broke: %@", [error localizedDescription]);
    }];
}

#pragma mark - UI events

- (IBAction)buttonTouch:(id)sender
{
    [self startUpload:nil];
}

#pragma mark - Dealloc

- (void) dealloc
{
    _status = nil;
    _progressBar = nil;
    _button = nil;
    _thumb = nil;
}

@end