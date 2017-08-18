#import "WRNTestRenderModule.h"
#import "RCCSyncRootView.h"

@interface WRNTestRenderModule()

@property (nonatomic, retain) RCCSyncRootView *lastRootView;

@end

@implementation WRNTestRenderModule

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(testCreate)
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    NSDictionary *props = @{@"name": @"Daniel", @"greeting": @"Hello World"};
    RCCSyncRootView *rootView = [[RCCSyncRootView alloc] initWithBridge:self.bridge moduleName:@"SyncExample" initialProperties:props];
    [UIApplication.sharedApplication.delegate.window.rootViewController.view addSubview:rootView];
    self.lastRootView = rootView;
  });
}

RCT_EXPORT_METHOD(testUpdate)
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    NSDictionary *props = @{@"name": @"John", @"greeting": @"Hello Snow"};
    RCCSyncRootView *rootView = self.lastRootView;
    if (rootView)
    {
      [rootView updateProps:props];
    }
  });
}

@end
