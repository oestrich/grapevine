import AnsiUp from 'ansi_up';
import _ from "underscore"
import PropTypes from 'prop-types';
import React, {Fragment} from 'react';
import Sizzle from "sizzle"
import {Socket} from "phoenix";

import {ClientSocket} from "./socket";
import Keys from './keys';

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");

const keys = new Keys();

document.addEventListener('keydown', e => {
  if (!keys.isModifierKeyPressed()) {
    document.getElementById('prompt').focus();
  }
});

const ansi_up = new AnsiUp();

class SocketProvider extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      text: ""
    }

    this.socket = new ClientSocket(this, this.props.game, userToken);
    this.socket.join();
  }

  appendText(message) {
    this.setState({text: this.state.text + message});
  }

  getChildContext() {
    return {
      socket: this.socket,
      text: this.state.text,
    };
  }

  render() {
    return (
      <div>{this.props.children}</div>
    );
  }
}

SocketProvider.childContextTypes = {
  text: PropTypes.string,
  socket: PropTypes.object,
}

class Prompt extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      text: "",
    };

    this.buttonSendMessage = this.buttonSendMessage.bind(this);
    this.onTextChange = this.onTextChange.bind(this);
    this.promptSendMessage = this.promptSendMessage.bind(this);
  }

  buttonSendMessage(e) {
    e.preventDefault();
    this.sendMessage();
  }

  promptSendMessage(e) {
    if (e.keyCode == 13) {
      this.sendMessage();
    }
  }

  sendMessage() {
    const {socket} = this.context;
    socket.send(`${this.state.text}\n`);
    this.setState({text: ""});
  }

  onTextChange(e) {
    this.setState({
      text: e.target.value,
    });
  }

  render() {
    let text = this.state.text;

    return (
      <div className="prompt">
        <input id="prompt"
          value={text}
          onChange={this.onTextChange}
          type="text"
          className="form-control"
          autoFocus={true}
          onKeyDown={this.promptSendMessage} />
        <button id="send" className="btn btn-primary" onClick={this.buttonSendMessage}>Send</button>
      </div>
    );
  }
}

Prompt.contextTypes = {
  socket: PropTypes.object,
};

class Terminal extends React.Component {
  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    this.scrollToBottom();
  }

  scrollToBottom() {
    this.el.scrollIntoView();
  }

  render() {
    let text = ansi_up.ansi_to_html(this.context.text);

    return (
      <div className="terminal">
        <div dangerouslySetInnerHTML={{__html: text}}></div>
        <div ref={el => { this.el = el; }} />
      </div>
    );
  }
}

Terminal.contextTypes = {
  text: PropTypes.string,
}

class Client extends React.Component {
  render() {
    return (
      <SocketProvider game={this.props.game}>
        <div className="play">
          <div className="alert alert-danger">
            <b>NOTE:</b> This web client is in <b>beta</b> and might close your connection at any time.
          </div>

          <div className="window">
            <Terminal />
            <Prompt />
          </div>
        </div>
      </SocketProvider>
    );
  }
}

export {Client}
