import PropTypes from 'prop-types';
import React, {Fragment} from "react";
import {connect} from 'react-redux';

import {
  Creators
} from "../redux/actions";

import {ClientSocket} from "../socket";

class SocketProvider extends React.Component {
  constructor(props) {
    super(props);

    this.socket = new ClientSocket(this, this.props.game, this.props.userToken, this.props.sessionToken);
    this.socket.join();
  }

  connected() {
    this.props.socketConnected();
  }

  disconnected() {
    this.props.socketDisconnected();
  }

  processText() {
    if (this.timer) {
      clearTimeout(this.timer);
    }

    this.props.socketGA();
  }

  appendText(message) {
    this.props.socketEcho(message);

    if (this.timer) {
      clearTimeout(this.timer);
    }

    this.timer = setTimeout(() => {
      this.processText();
    }, 200);
  }

  receiveGMCP(message, data) {
    this.props.socketReceiveGMCP(message, data);
  }

  setOption(option) {
    this.props.socketRecieveOption(option);
  }

  getChildContext() {
    return {
      socket: this.socket,
    };
  }

  render() {
    return (
      <Fragment>{this.props.children}</Fragment>
    );
  }
}

SocketProvider.childContextTypes = {
  socket: PropTypes.object,
}

export default SocketProvider = connect(null, {
  socketConnected: Creators.socketConnected,
  socketDisconnected: Creators.socketDisconnected,
  socketEcho: Creators.socketEcho,
  socketGA: Creators.socketGA,
  socketReceiveGMCP: Creators.socketReceiveGMCP,
  socketRecieveOption: Creators.socketRecieveOption
})(SocketProvider);
