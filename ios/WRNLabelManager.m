#import "WRNLabelManager.h"

@implementation WRNLabelManager

RCT_EXPORT_MODULE()

RCT_REMAP_VIEW_PROPERTY(label, text, NSString)

- (UIView *)view
{
  return [[UILabel alloc] init];
}

@end
