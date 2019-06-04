import PropTypes from 'prop-types';
import React, {Fragment} from "react";
import {connect} from 'react-redux';

import {Creators} from "../redux/actions";

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
    this.props.socketGA();
  }

  appendText(message) {
    this.props.socketEcho(message);
    this.processText();
  }

  receiveConnection(data) {
    this.props.socketReceiveConnection(data);
  }

  receiveGMCP(message, data) {
    this.props.socketReceiveGMCP(message, data);
  }

  receiveOAuth(data) {
    this.props.socketReceiveOAuth(data);
  }

  setOption(option) {
    this.props.socketReceiveOption(option);
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
  socketReceiveConnection: Creators.socketReceiveConnection,
  socketReceiveGMCP: Creators.socketReceiveGMCP,
  socketReceiveOAuth: Creators.socketReceiveOAuth,
  socketReceiveOption: Creators.socketReceiveOption
})(SocketProvider);
