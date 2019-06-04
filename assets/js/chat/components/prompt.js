import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {ConnectionStatus} from "./connection_status";
import {Creators} from "../redux/actions";
import {getSocketActiveChannel} from "../redux/selectors";

class Prompt extends React.Component {
  constructor(props) {
    super(props);

    this.buttonSendMessage = this.buttonSendMessage.bind(this);
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

  render() {
    let text = this.state.text;

    return (
      <div className="prompt">
        <ConnectionStatus />

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
  return {activeChannel};
};

Prompt = connect(mapStateToProps, {
  socketReceiveChat: Creators.socketReceiveChat,
})(Prompt);

export {Prompt};
