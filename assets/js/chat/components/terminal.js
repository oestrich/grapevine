import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';

import {getSocketMessages} from "../redux/selectors";

class SystemMessage extends React.Component {
  render() {
    return (
      <div className={this.props.color}>{this.props.text}</div>
    );
  }
}

class TextMessage extends React.Component {
  channel() {
    let channel = this.props.channel;

    return (
      <span className="channel">[{channel}]</span>
    );
  }

  name() {
    let name = this.props.name;
    let game = this.props.game;

    return (
      <span className="player">{name}@{game}</span>
    );
  }

  text() {
    let message = this.props.message;

    return (
      <span className="text">{message}</span>
    );
  }

  render() {
    return (
      <div>{this.channel()} {this.name()}: {this.text()}</div>
    );
  }
}

class Terminal extends React.Component {
  renderMessage(message, i) {
    switch (message.type) {
      case "system":
        return (
          <SystemMessage key={i} color={message.color} text={message.text} />
        );

      case "broadcast":
        return (
          <TextMessage key={i} channel={message.channel} game={message.game} name={message.name} message={message.message} />
        );
    }
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    this.scrollToBottom();
  }

  componentWillUpdate() {
    let visibleBottom = this.terminal.scrollTop + this.terminal.clientHeight;
    this.triggerScroll = !(visibleBottom + 250 < this.terminal.scrollHeight);
  }

  scrollToBottom() {
    if (this.triggerScroll) {
      this.el.scrollIntoView();
    }
  }

  render() {
    let messages = this.props.messages;

    return (
      <div ref={el => { this.terminal = el; }} className="terminal">
        {_.map(messages, this.renderMessage)}
        <div ref={el => { this.el = el; }} />
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const messages = getSocketMessages(state);
  return {messages};
};

export default Terminal = connect(mapStateToProps)(Terminal);
