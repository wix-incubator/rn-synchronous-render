#import "RCCSyncRegistry.h"

@implementation RCCSyncRegistry

RCT_EXPORT_MODULE();

-(instancetype)init
{
  self = [super init];
  self.registry = [NSMutableDictionary new];
  self.lastTag = @(1000001);
  return self;
}

RCT_EXPORT_METHOD(registerRecipe:(NSString*)registeredName props:(NSDictionary*)props recipe:(NSArray*)recipe)
{
  [self.registry setObject:@{@"props": props, @"recipe": recipe} forKey:registeredName];
}

@end
