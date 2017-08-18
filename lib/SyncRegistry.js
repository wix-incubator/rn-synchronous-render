import _ from 'lodash';
import React from 'react';
const ReactNative = require('react-native/Libraries/Renderer/shims/ReactNative');
const NativeModules = require('react-native').NativeModules;
const UIManager = NativeModules.UIManager;
const RCCSyncRegistry = NativeModules.RCCSyncRegistry;

const origCreateView = UIManager.createView;
const origSetChildren = UIManager.setChildren;

export default class SyncRegistry {
  static registerComponent(registeredName, componentGenerator, propNames) {
    const Template = componentGenerator();
    const props = {};
    for (const propName of propNames) {
      props[propName] = `__${propName}__`;
    }
    const recipe = [];
    prepareRecipeBySwizzlingUiManager(recipe);
    const rendered = ReactNative.render(<Template {...props} />, 1);
    restoreUiManager();
    RCCSyncRegistry.registerRecipe(registeredName, props, recipe);
  }
}

function prepareRecipeBySwizzlingUiManager(recipe) {
  UIManager.createView = (...args) => {
    recipe.push({ cmd: 'createView', args });
  }
  UIManager.setChildren = (...args) => {
    recipe.push({ cmd: 'setChildren', args });
  }
}

function restoreUiManager() {
  UIManager.createView = origCreateView;
  UIManager.setChildren = origSetChildren;
}
