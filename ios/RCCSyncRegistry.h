#import <UIKit/UIKit.h>
#import <React/RCTBridgeModule.h>

@interface RCCSyncRegistry : NSObject <RCTBridgeModule>

@property (nonatomic, strong) NSMutableDictionary *registry;
@property (nonatomic, strong) NSNumber *lastTag;

@end
