# React Native Synchronous Render
> Experiment and proof of concept

## Why

Rendering in React Native (and React in general) is *asynchronous*. Updates made to React components from the JavaScript thread are batched together periodically and sent over the React Native bridge to be performed in the native realm (eventually on the main thread). This strategy brings performance benefits in the majority of cases but causes performance issues in some specific scenarios.

One example is lists in React Native. When scrolling the list very fast, the scroll is handled in the native realm and new cells in the list must be created and populated with data as the user scrolls. Since rendering from JavaScript is asynchronous, we have to go twice over the bridge in order to layout a new cell. Once from native to JavaScript to perform the render and then back to update the native properties. This performance overhead of jumping between realms may cause fill-rate delays which users experience as flickering white cells for a short while.

Another example is pushing a new sceen from native navigation solutions. The push takes place in the native realm, but rendering of the content takes place in the JavaScript realm. Once again since rendering from JavaScript is asynchronous, we have to go twice over the bridge in order to layout the screen. This performance overhead of jumping between realms may cause render delays which users experience as a white flicker for a short while.

This is a conceptual problem which manifests itself as degraded user experience in React Native apps and prevents them from truly competing with pure native apps in some scenarios.

## What

If we had some way to render components directly from the native realm without going to the JavaScript realm, we could use this ability to remove the overhead in the above scenarios. We will call this ability *synchronous rendering* since it avoids the inherent asynchronicity of React. We will only use this ability in the rare conditions where synchronicity in rendering is required to achieve improved user experience beacause, as we've said before, asynchronicity in render is usually a good thing.

This entire approach is a bit tricky to implement because we *want* to specify the render logic in JavaScript. Using JSX to describe UI and layout is awesome, we don't want to miss that. So how can we specify the render logic in JavaScript, but perform it without JavaScript?

## API

Before thinking about implementation, let's define the API. The normal React component tree is [connected](https://github.com/wix/rn-synchronous-render/blob/master/ios/SyncRender/AppDelegate.m#L14) to our app from native via an [`RCTRootView`](https://github.com/facebook/react-native/blob/master/React/Base/RCTRootView.h). The native root view is provided with the registered module name and some initial props. In JavaScript, a React component is registered in `AppRegistry` under the same module name:

```jsx
class App extends Component {
  render() {
    return (
      <View style={{flex: 1}}>
        <Text>Welcome to the app</Text>
      </View>
    );
  }
}

AppRegistry.registerComponent('App', () => App);
```

In the native side:

```objc
NSDictionary *props = @{};
RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:_bridge 
                                                 moduleName:@"App" 
                                          initialProperties:props];
```

We'll define our new *synchronous* components in the same way. We'll have a new type of root view called `RCCSyncRootView` which will be provided in native with a registered module name and some initial props. In JavaScript, a React component will be registered in the exact same way under a new registry called `SyncRegistry`:

```jsx
class SyncSnippet extends Component {
  render() {
    return (
      <View style={{flex: 1}}>
        <Text>I am synchronous</Text>
      </View>
    );
  }
}

SyncRegistry.registerComponent('SyncSnippet', () => SyncSnippet);
```

From the native side, the `RCCSyncRootView` would support two main actions: being created and updating its props. The main requirement we have, which is the novel thing with this approach, is that these two actions will complete in the native realm **without jumping over the bridge to JavaScript**!

The API for the two actions will look like:

```objc
NSDictionary *props = @{@"name": @"John Snow"};
RCCSyncRootView *rootView = [[RCCSyncRootView alloc] initWithBridge:_bridge 
                                                         moduleName:@"SyncSnippet" 
                                                  initialProperties:props];
[_someView addSubview:rootView];
```

```
NSDictionary *props = @{@"name": @"Mister Targaryen"};
[rootView updateProps:props];
```

Keep in mind that `RCCSyncRootView` extends `RCTRootView` so it supports the same interface.

## How

This repo contains a working proof of concept that satisfies the above requirements. How does it work?

Since the React logic for the synchronous components is still defined in JavaScript, when the component is registered in `SyncRegistry` (usually on JavaScript initialization), we're going to create a serializable template recipe of how to instantiate it from native. This template will be serialized and sent over the bridge **once** during initialization.

We'll store the recipe in native and when we need to create a new `RCCSyncRootView` or update its props, we'll go over the recipe in native and manually execute the low level [`UIManager`](https://github.com/facebook/react-native/blob/d81e5492974e831aba06e435e2b0504a680a20f8/React/Modules/RCTUIManager.m#L940) commands needed. If you're not familiar with `UIManager`, this is the core native module that actually creates and updates the native counterparts of the React components in React Native. When React reconciles the component tree in JavaScript, the diff is translated into `UIManager` commands that are sent over the bridge. This happens when React renders a component. These [unit tests](https://github.com/facebook/react/blob/50d905b0838857e76f7eb2f0875047c264f4c24e/src/renderers/native/__tests__/ReactNativeMount-test.js#L35) do a good job of explaining the spec in code.

But how can we know which `UIManager` commands are needed? Well.. we can cheat. We can run the React Native `render` function in JavaScript manually during initialization and swizzle the `UIManager` temporarily so instead of actually sending the real commands over the bridge, it will just write them down in our recipe. You can see this [here](https://github.com/wix/rn-synchronous-render/blob/bcb75d4117e8560c8793c15afd5ba23dc460e526/lib/SyncRegistry.js#L19).

## Limitations

When rendering a *synchronous* component in runtime, we're just following the recipe and not actually running the JavaScript render code. This means our synchronous component tree has to be 100% declarative. We're not allowed to place any business logic in it except passing around props.

But what if our components require imperative business logic during render? We will have to implement this in native. I'm thinking about defining a new class of React Native components called "declarative components" which satisfy this requirement. Only these types of components could be used for synchronous render. We can eventually port all the core React Native components to be part of this family, just by moving any business logic they have in JavaScript to native. A bit time consuming but not difficult.

## Next Steps

One of the most interesting use-cases relevant for applying this technique is lists. We already have an older working proof of concept for a list view in React Native which uses native row recycling and *synchronous* rendering - the code is available [here](https://github.com/wix/BindingListView/tree/better-bind).

The new API presented here with a synchronous root view is much cleaner and general purpose. A nice exercise would be to take the list view proof of concept and reimplement it with synchronous root views for the rows.

## Thanks

Thanks to @DanielZlotin and @bogobogo for helping bring the poc to life.
