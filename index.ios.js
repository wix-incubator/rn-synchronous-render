import React, { Component } from 'react';
import { AppRegistry, TextInput, Button, requireNativeComponent, NativeModules, View } from 'react-native';
import SyncRegistry from './lib/SyncRegistry';

const WRNLabel = requireNativeComponent('WRNLabel', null);
const WRNTestRender = NativeModules.WRNTestRenderModule;

class App extends Component {
  render() {
    return (
      <View style={{flex: 1, padding: 10, justifyContent: 'center', backgroundColor: '#F5FCFF'}}>
        <Button
          title="Render new SyncRootView from native"
          onPress={this.onCreatePress.bind(this)}
        />
        <Button
          title="Update SyncRootView props from native"
          onPress={this.onUpdatePress.bind(this)}
        />
      </View>
    );
  }
  onCreatePress() {
    WRNTestRender.testCreate();
  }
  onUpdatePress() {
    WRNTestRender.testUpdate();
  }
}

AppRegistry.registerComponent('App', () => App);

class SyncExample extends Component {
  render() {
    return (
      <View style={{padding: 10, width: 120, height: 80, backgroundColor: 'red'}}>
        <WRNLabel
          label={this.props.name}
          style={{width: 100, height: 40, backgroundColor: 'yellow'}}
        />
        <TextInput
          editable={false}
          value={this.props.greeting}
        />
      </View>
    );
  }
}

SyncRegistry.registerComponent('SyncExample', () => SyncExample, ['name', 'greeting']);
