import _ from "underscore";
import PropTypes from 'prop-types';
import React, {Fragment} from 'react';
import Sizzle from "sizzle"
import {Socket} from "phoenix";
import {Provider, connect} from 'react-redux';

import {ClientSocket} from "./socket";
import Keys from './keys';
import {store, socketEcho, socketGA, socketReceiveGMCP, socketRecieveOption} from "./redux/store";
import {getSocketLines, getSocketGMCP} from "./redux/store";

import Gauges from "./components/gauges";

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");
let sessionToken = body.getAttribute("data-session-token");

const keys = new Keys();

document.addEventListener('keydown', e => {
  if (!keys.isModifierKeyPressed()) {
    document.getElementById('prompt').focus();
  }
});

class SocketProvider extends React.Component {
  constructor(props) {
    super(props);

    this.socket = new ClientSocket(this, this.props.game, userToken, sessionToken);
    this.socket.join();
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

SocketProvider = connect(null, {socketEcho, socketGA, socketReceiveGMCP, socketRecieveOption})(SocketProvider);

class Prompt extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      history: [],
      index: -1,
      currentText: "",
      displayText: "",
    };

    this.buttonSendMessage = this.buttonSendMessage.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onTextChange = this.onTextChange.bind(this);

    this.shouldSelect = false;
  }

  buttonSendMessage(e) {
    e.preventDefault();
    this.sendMessage();
  }

  onKeyDown(e) {
    switch (e.keyCode) {
      case 13: {
        this.sendMessage();
        e.target.select();

        break;
      }
      case 38: { // up
        e.preventDefault();
        this.shouldSelect = true;
        let index = this.state.index + 1;

        if (this.state.history[index] != undefined) {
          this.setState({
            index: index,
            displayText: this.state.history[index]
          });
        }

        break;
      }
      case 40: { // down
        e.preventDefault();
        this.shouldSelect = true;
        let index = this.state.index - 1;

        if (index == -1) {
          this.setState({
            index: 0,
            displayText: this.state.currentText
          });
        } else if (this.state.history[index] != undefined) {
          this.setState({
            index: index,
            displayText: this.state.history[index]
          });
        }

        break;
      }
    }
  }

  sendMessage() {
    const {socket} = this.context;
    socket.send(`${this.state.displayText}\n`);
    this.addMessageHistory();
  }

  addMessageHistory() {
    let history = this.state.history;

    if (_.first(this.state.history) == this.state.displayText) {
      this.setState({
        index: -1
      });
    } else {
      history = [this.state.displayText, ...history];
      history = _.first(history, 10);

      this.setState({
        history,
        index: 0,
      });
    }
  }

  onTextChange(e) {
    this.setState({
      index: -1,
      currentText: e.target.value,
      displayText: e.target.value,
    });
  }

  componentDidUpdate() {
    if (this.shouldSelect) {
      this.shouldSelect = false;
      this.prompt.select();
    }
  }

  render() {
    let displayText = this.state.displayText;

    return (
      <div className="prompt">
        <input id="prompt"
          value={displayText}
          onChange={this.onTextChange}
          type="text"
          className="form-control"
          autoFocus={true}
          onKeyDown={this.onKeyDown}
          ref={el => { this.prompt = el; }} />
        <button id="send" className="btn btn-primary" onClick={this.buttonSendMessage}>Send</button>
      </div>
    );
  }
}

Prompt.contextTypes = {
  socket: PropTypes.object,
};

class AnsiText extends React.Component {
  textStyle(parsed) {
    let style = {};

    if (parsed.bg) {
      style.backgroundColor = `rgb(${parsed.bg})`;
    }

    if (parsed.fg) {
      style.color = `rgb(${parsed.fg})`;
    }

    if (parsed.decoration == "bold") {
      style.fontWeight = "bolder";
    }

    return style;
  }

  render() {
    let text = this.props.text;

    return (
      <span style={this.textStyle(text)}>{text.content}</span>
    );
  }
}

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
    let lines = this.props.lines;

    return (
      <div className="terminal">
        {_.map(lines, text => {
          return (
            <AnsiText key={text.id} text={text} />
          );
        })}
        <div ref={el => { this.el = el; }} />
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const lines = getSocketLines(state);
  return {lines};
};

Terminal = connect(mapStateToProps)(Terminal);

class Client extends React.Component {
  render() {
    return (
      <Provider store={store}>
        <SocketProvider game={this.props.game}>
          <div className="play">
            <div className="alert alert-danger">
              <b>NOTE:</b> This web client is in <b>beta</b> and might close your connection at any time.
            </div>

            <div className="window">
              <Terminal />
              <Gauges gauges={this.props.gauges} />
              <Prompt />
            </div>
          </div>
        </SocketProvider>
      </Provider>
    );
  }
}

export {Client}
