#import <QuartzCore/CALayer.h>
#import "TransloaditRequest.h"

@interface IphoneSdkViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> 

@property IBOutlet UIButton *button;
@property IBOutlet UIImageView *thumb;
@property IBOutlet UIProgressView *progressBar;
@property IBOutlet UILabel *status;
@property IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)buttonTouch:(id)sender;

@end