import React from 'react';
import {Provider} from 'react-redux';

import {Prompt} from "./components/prompt";
import {SocketProvider} from "./components/socket_provider";
import Terminal from "./components/terminal";

import {SocketCreators} from "./redux/socketReducer";
import {makeStore} from "./redux/store";
import {ClientSocket} from "./socket";

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");

export class Client extends React.Component {
  constructor(props) {
    super(props);

    this.store = makeStore();
  }

  componentWillMount() {
    this.socket = new ClientSocket(this.store, userToken);
    this.socket.join();

    this.props.channels.map(channelName => {
      this.store.dispatch(SocketCreators.socketSubscribeChannel(this.socket, channelName));
    });
  }

  render() {
    let store = this.store;

    return (
      <Provider store={store}>
        <SocketProvider socket={this.socket}>
          <div className="chat">
            <div className="window">
              <Terminal />
              <Prompt />
            </div>
          </div>
        </SocketProvider>
      </Provider>
    );
  }
}
