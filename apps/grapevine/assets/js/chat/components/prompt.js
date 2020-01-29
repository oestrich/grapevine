import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {ConnectionStatus} from "./connection_status";
import {PromptCreators} from "../redux/promptReducer";
import {getPromptActiveChannel, getPromptMessage, getSocketChannels} from "../redux/selectors";

class Prompt extends React.Component {
  constructor(props) {
    super(props);

    this.buttonSendMessage = this.buttonSendMessage.bind(this);
    this.onChannelChange = this.onChannelChange.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onTextChange = this.onTextChange.bind(this);
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
    const message = this.props.message;

    if (message === "") {
      return;
    }

    this.context.socket.send(this.props.activeChannel, message);
    this.props.setMessage("");
  }

  onTextChange(e) {
    this.props.setMessage(e.target.value);
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
    let message = this.props.message;

    return (
      <div className="prompt">
        <ConnectionStatus />

        {this.renderAciveChannel()}

        <input id="prompt"
          value={message}
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
  const activeChannel = getPromptActiveChannel(state);
  const channels = getSocketChannels(state);
  const message = getPromptMessage(state);

  return {activeChannel, channels, message};
};

Prompt = connect(mapStateToProps, {
  setMessage: PromptCreators.promptSetMessage,
  setActiveChannel: PromptCreators.promptSetActiveChannel,
})(Prompt);

export {Prompt};
