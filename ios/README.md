# React Native Synchronous Render
> Experiment and proof of concept

### Why

Rendering in React Native (and React in general) is *asynchronous*. Updates made to React components from the JavaScript thread are batched together periodically and sent over the React Native bridge to be performed in the native realm (on the main thread). This strategy brings performance benefits in the majority of cases but causes performance issues in some specific scenarios.

One example is lists in React Native. When scrolling the list very fast, the scroll is handled in the native realm and new cells in the list must be created and populated with data as the user scrolls. Since rendering from JavaScript is asynchronous, we have to go twice over the bridge in order to layout a new cell. Once from native to JavaScript to perform the render and then back to update the native properties. This performance overhead of jumping between realms may cause fill-rate delays which users experience as flickering white cells for a short while.

Another example is pushing a new sceen from native navigation solutions. The push takes place in the native realm, but rendering of the content takes place in the JavaScript realm. Once again since rendering from JavaScript is asynchronous, we have to go twice over the bridge in order to layout the screen. This performance overhead of jumping between realms may cause render delays which users experience as a white flicker for a short while.

### What

If we had some way to render components directly from the native realm without going to the JavaScript realm, we could use this ability to remove the overhead in the above scenarios. We will call this ability *synchronous rendering* since it avoids the inherent asynchronicity of React.

This approach is a bit tricky to implement because we *want* to specify the render logic in JavaScript. Using JSX to describe UI and layout is awesome, we don't want to miss that. So how can we specify the render logic in JavaScript, but perform it without JavaScript?

### How

TBD
