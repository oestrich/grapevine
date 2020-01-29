import React from 'react';
import {Provider} from 'react-redux';
import _ from 'underscore';

import Keys from './keys';
import {Creators} from "./redux/actions";
import {makeStore} from "./redux/store";

import Gauges from "./components/gauges";
import Modals from "./components/modals";
import {OAuthAuthorization} from "./components/oauth";
import Prompt from "./components/prompt";
import {Settings, SettingsToggle} from "./components/settings";
import SocketProvider from "./components/socket_provider";
import Terminal from "./components/terminal";
import TopDock from "./components/top_dock";

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");
let sessionToken = body.getAttribute("data-session-token");

let store = null;

if (document.querySelector("[data-page=play]")) {
  store = makeStore();

  const keys = new Keys();

  document.addEventListener('keydown', e => {
    if (!keys.isModifierKeyPressed()) {
      document.getElementById('prompt').focus();
    }
  });

  if ("speechSynthesis" in window) {
    speechSynthesis.onvoiceschanged = () => {
      let voices = _.filter(speechSynthesis.getVoices(), (voice) => {
        return voice.name.match(/English/g);
      });
      voices = _.map(voices, (voice) => { return voice.name; });
      let action = Creators.voiceSetVoices(voices);
      store.dispatch(action);
    };
  }
}

class Client extends React.Component {
  render() {
    let dockedGauges = _.filter(this.props.gauges, gauge => {
      return gauge.is_docked;
    });

    let undockedGauges = _.reject(this.props.gauges, gauge => {
      return gauge.is_docked;
    });

    return (
      <Provider store={store}>
        <SocketProvider game={this.props.game} userToken={userToken} sessionToken={sessionToken}>
          <div className="play">
            <div className="window">
              <Terminal />
              <Settings />
              <Modals />
              <OAuthAuthorization game={this.props.game} />
              <SettingsToggle />
              <TopDock>
                <Gauges gauges={undockedGauges} />
              </TopDock>
              <Gauges gauges={dockedGauges} />
              <Prompt />
            </div>
          </div>
        </SocketProvider>
      </Provider>
    );
  }
}

export {Client}
