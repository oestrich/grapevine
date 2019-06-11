import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {ConnectionStatus} from "./connection_status";
import {Creators} from "../redux/actions";
import {getSocketActiveChannel, getSocketChannels} from "../redux/selectors";

class Prompt extends React.Component {
  constructor(props) {
    super(props);

    this.buttonSendMessage = this.buttonSendMessage.bind(this);
    this.onChannelChange = this.onChannelChange.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onTextChange = this.onTextChange.bind(this);

    this.state = {
      text: "",
    }
  }

  buttonSendMessage(e) {
    e.preventDefault();
    this.sendMessage();
  }

  onKeyDown(e) {
    switch (e.keyCode) {
      case 13: {
        this.sendMessage();
        break;
      }
    }
  }

  sendMessage() {
    const message = this.state.text;
    this.context.socket.send(this.props.activeChannel, message);
    this.setState({text: ""});
  }

  onTextChange(e) {
    this.setState({text: e.target.value});
  }

  onChannelChange(e) {
    this.props.setActiveChannel(e.target.value);
  }

  renderAciveChannel() {
    return (
      <select value={this.props.activeChannel} className="active-channel form-control" onChange={this.onChannelChange}>
        {this.props.channels.map((channel, i) => {
          return (
            <option key={i}>{channel}</option>
          );
        })}
      </select>
    );
  }

  render() {
    let text = this.state.text;

    return (
      <div className="prompt">
        <ConnectionStatus />

        {this.renderAciveChannel()}

        <input id="prompt"
          value={text}
          onChange={this.onTextChange}
          type="text"
          className="form-control"
          autoFocus={true}
          onKeyDown={this.onKeyDown} />
        <button id="send" className="btn btn-primary" onClick={this.buttonSendMessage}>Send</button>
      </div>
    );
  }
}

Prompt.contextTypes = {
  socket: PropTypes.object,
};

let mapStateToProps = (state) => {
  const activeChannel = getSocketActiveChannel(state);
  const channels = getSocketChannels(state);
  return {activeChannel, channels};
};

Prompt = connect(mapStateToProps, {
  setActiveChannel: Creators.socketSetActiveChannel,
})(Prompt);

export {Prompt};
