/**
 * Redux
 */
import { Provider, connect } from 'react-redux';
import { combineReducers, createStore } from 'redux';

// Actions
export const SOCKET_ECHO = "SOCKET_ECHO";
export const SOCKET_GA = "SOCKET_GA";
export const SOCKET_GMCP = "SOCKET_GMCP";
export const SOCKET_OPTION = "SOCKET_OPTION";

export const socketEcho = (text) => ({
  type: SOCKET_ECHO,
  payload: {text}
});

export const socketGA = () => ({
  type: SOCKET_GA,
});

export const socketReceiveGMCP = (message, data) => ({
  type: SOCKET_GMCP,
  payload: {message, data}
});

export const socketRecieveOption = ({key, value}) => ({
  type: SOCKET_OPTION,
  payload: {key, value},
});

// Selectors

export const getSocketState = (state) => {
  return state.socket;
}

export const getSocketLines = (state) => {
  return getSocketState(state).lines;
};

export const getSocketGMCP = (state) => {
  return getSocketState(state).gmcp;
};

// Reducers
const initialState = {
  buffer: "",
  lines: [],
  lineId: 0,
  gmcp: {},
}

let socketReducer = function(state = initialState, action) {
  switch (action.type) {
    case SOCKET_ECHO: {
      const {text} = action.payload;
      return {...state, buffer: state.buffer + text};
    }
    case SOCKET_GA: {
      if (state.buffer === "") {
        return state;
      }

      let increment = 0;
      let parsedText = Anser.ansiToJson(state.buffer);

      parsedText = _.map(parsedText, text => {
        text = {
          id: state.lineId + increment,
          content: text.content,
          bg: text.bg,
          fg: text.fg,
          decoration: text.decoration
        };

        increment++;

        return text;
      });

      let lines = [...state.lines, ...parsedText];

      return {...state, buffer: "", lines: lines, lineId: state.lineId + increment};
    }
    case SOCKET_GMCP: {
      const {message, data} = action.payload;
      return {...state, gmcp: {...state.gmcp, [message]: data}};
    }
    case SOCKET_OPTION: {
      let option = action.payload;

      switch (option.key) {
        case "prompt_type": {
          return {...state, options: {...state.options, promptType: option.value}};
        }
        default: {
          return state;
        }
      }
    }
    default: {
      return state;
    }
  }
}

let rootReducer = combineReducers({socket: socketReducer});

let store = createStore(rootReducer, window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__());

/**
 * React
 */
import Anser from "anser";
import _ from "underscore"
import PropTypes from 'prop-types';
import React, {Fragment} from 'react';
import Sizzle from "sizzle"
import {Socket} from "phoenix";

import {ClientSocket} from "./socket";
import Keys from './keys';

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

class GaugeProvider extends React.Component {
  getChildContext() {
    return {
      gauges: this.props.gauges,
    };
  }

  render() {
    return (
      <div>{this.props.children}</div>
    );
  }
}

GaugeProvider.childContextTypes = {
  gauges: PropTypes.array,
}

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

class Gauges extends React.Component {
  gaugesEmpty() {
    let gauges = this.context.gauges;
    return gauges.length == 0;
  }

  dataEmpty() {
    let gmcp = this.props.gmcp;
    return Object.entries(gmcp).length === 0 && gmcp.constructor === Object;
  }

  render() {
    let gauges = this.context.gauges;

    if (this.gaugesEmpty() || this.dataEmpty()) {
      return null;
    }

    return (
      <div className="gauges">
        {_.map(gauges, (gauge, i) => {
          return (
            <Gauge gauge={gauge} key={i} />
          );
        })}
      </div>
    );
  }
}

Gauges.contextTypes = {
  gauges: PropTypes.array,
}

mapStateToProps = (state) => {
  const gmcp = getSocketGMCP(state);
  return {gmcp};
};

Gauges = connect(mapStateToProps)(Gauges);

class Gauge extends React.Component {
  render() {
    let {name, message, value, max, color} = this.props.gauge;

    let data = this.props.gmcp[message];

    if (data) {
      let currentValue = data[value];
      let maxValue = data[max];

      let width = currentValue / maxValue * 100;

      let className = `gauge ${color}`;

      return (
        <div className={className}>
          <div className="gauge-bar" style={{width: `${width}%`}} />
          <span>{currentValue}/{maxValue} {name}</span>
        </div>
      );
    } else {
      return null;
    }
  }
}

mapStateToProps = (state) => {
  const gmcp = getSocketGMCP(state);
  return {gmcp};
};

Gauge = connect(mapStateToProps)(Gauge);

class Client extends React.Component {
  render() {
    return (
      <Provider store={store}>
        <SocketProvider game={this.props.game}>
          <GaugeProvider gauges={this.props.gauges}>
            <div className="play">
              <div className="alert alert-danger">
                <b>NOTE:</b> This web client is in <b>beta</b> and might close your connection at any time.
              </div>

              <div className="window">
                <Terminal />
                <Gauges />
                <Prompt />
              </div>
            </div>
          </GaugeProvider>
        </SocketProvider>
      </Provider>
    );
  }
}

export {Client}
