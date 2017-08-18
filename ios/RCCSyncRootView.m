
#import "RCCSyncRootView.h"
#import "RCCSyncRegistry.h"
#import <React/RCTUIManager.h>

@protocol UIManagerInternals
-(void) createView:(NSNumber *)reactTag viewName:(NSString *)viewName rootTag:(NSNumber *)rootTag props:(NSDictionary *)props;
-(void) updateView:(NSNumber *)reactTag viewName:(NSString *)viewName props:(NSDictionary *)props;
-(void) setChildren:(NSNumber *)containerTag reactTags:(NSArray<NSNumber *> *)reactTags;
@end

@interface RCCSyncRootView()

@property (nonatomic, retain) NSMutableDictionary *recipeTagToTag;

@end

@implementation RCCSyncRootView

- (void)runApplication:(RCTBridge *)bridge
{
  NSNumber *rootTag = [self performSelector:@selector(reactTag) withObject:nil];
  
  RCCSyncRegistry *module = [self registryModule];
  NSDictionary *details = [module.registry objectForKey:self.moduleName];
  NSDictionary *binding = details[@"props"];
  NSDictionary *inverseBinding = [self invertDictionary:binding];
  NSArray *recipe = details[@"recipe"];
  
  RCTUIManager<UIManagerInternals> *uiManager = (RCTUIManager<UIManagerInternals>*)self.bridge.uiManager;
  
  self.recipeTagToTag = [NSMutableDictionary new];
  self.recipeTagToTag[@(1)] = rootTag;
  
  for (NSDictionary *call in recipe)
  {

    if ([call[@"cmd"] isEqualToString:@"createView"])
    {
      NSNumber *tag = [self translateTag:self.recipeTagToTag recipeTag:call[@"args"][0]];
      NSDictionary *props = [self bindProps:call[@"args"][3] binding:binding inverseBinding:inverseBinding values:self.appProperties onlyChanges:NO];
      
      dispatch_async([uiManager methodQueue], ^
      {
        [uiManager createView:tag viewName:call[@"args"][1] rootTag:rootTag props:props];
      });
      
    } else if ([call[@"cmd"] isEqualToString:@"setChildren"])
    {
      NSNumber *tag = [self translateTag:self.recipeTagToTag recipeTag:call[@"args"][0]];
      NSMutableArray *childTags = [NSMutableArray new];
      NSArray *arr = call[@"args"][1];
      for (NSNumber *childTag in arr)
      {
        [childTags addObject:[self translateTag:self.recipeTagToTag recipeTag:childTag]];
      }
      
      dispatch_async([uiManager methodQueue], ^
      {
        [uiManager setChildren:tag reactTags:childTags];
      });
    }
    
  }
}

-(void)updateProps:(NSDictionary *)newProps
{
  if (self.recipeTagToTag == nil) return;
  
  RCCSyncRegistry *module = [self registryModule];
  NSDictionary *details = [module.registry objectForKey:self.moduleName];
  NSDictionary *binding = details[@"props"];
  NSDictionary *inverseBinding = [self invertDictionary:binding];
  NSArray *recipe = details[@"recipe"];
  
  RCTUIManager<UIManagerInternals> *uiManager = (RCTUIManager<UIManagerInternals>*)self.bridge.uiManager;
  
  for (NSDictionary *call in recipe)
  {
    
    if ([call[@"cmd"] isEqualToString:@"createView"])
    {
      NSNumber *tag = [self translateTag:self.recipeTagToTag recipeTag:call[@"args"][0]];
      NSDictionary *props = [self bindProps:call[@"args"][3] binding:binding inverseBinding:inverseBinding values:newProps onlyChanges:YES];
      if (props == nil) continue;
      
      dispatch_async([uiManager methodQueue], ^
      {
        [uiManager updateView:tag viewName:call[@"args"][1] props:props];
      });
    }
    
  }
  
  dispatch_async([uiManager methodQueue], ^
  {
    [uiManager batchDidComplete];
  });
}

-(NSDictionary*)invertDictionary:(NSDictionary*)dict
{
  NSArray * keys = [dict allKeys];
  NSArray * vals = [dict objectsForKeys:keys notFoundMarker:[NSNull null]];
  return [NSDictionary dictionaryWithObjects:keys forKeys:vals];
}

-(NSDictionary*)bindProps:(id)props binding:(NSDictionary*)binding inverseBinding:(NSDictionary*)inverseBinding values:(NSDictionary*)values onlyChanges:(BOOL)onlyChanges
{
  if (props == [NSNull null]) return nil;
  NSMutableDictionary *res = [NSMutableDictionary new];
  
  for (NSString *propName in (NSDictionary*)props)
  {
    id propValue = [props objectForKey:propName];
    if (!onlyChanges)
    {
      [res setObject:propValue forKey:propName];
    }
    
    if ([propValue isKindOfClass:[NSString class]])
    {
      NSString *valueKey = [inverseBinding objectForKey:propValue];
      if (valueKey)
      {
        id newValue = [values objectForKey:valueKey];
        if (newValue == nil) newValue = [NSNull null];
        [res setObject:newValue forKey:propName];
      }
    }
  }
  
  if ([res count] == 0) return nil;
  return res;
}

-(NSNumber*)allocateTag
{
  long result = [[self registryModule].lastTag longValue];
  result++;
  if (result % 10 == 1)
  {
    result++;
  }
  [self registryModule].lastTag = @(result);
  return @(result);
}

-(NSNumber*)translateTag:(NSMutableDictionary*)recipeTagToTag recipeTag:(NSNumber*)recipeTag
{
  if ([recipeTagToTag objectForKey:recipeTag]) return [recipeTagToTag objectForKey:recipeTag];
  NSNumber *result = [self allocateTag];
  [recipeTagToTag setObject:result forKey:recipeTag];
  return result;
}

-(RCCSyncRegistry*)registryModule
{
  return [self.bridge moduleForClass:RCCSyncRegistry.class];
}

@end
