import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';
import moment from 'moment';

import {getSocketMessages} from "../redux/selectors";

class SystemMessage extends React.Component {
  render() {
    return (
      <div className={this.props.color}>{this.props.text}</div>
    );
  }
}

class TextMessage extends React.Component {
  timestamp() {
    let insertedAt = moment(this.props.insertedAt);
    let timestamp = insertedAt.format("YYYY-MM-DD hh:mm A");

    return (
      <span className="timestamp">{timestamp}</span>
    );
  }

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
      <div>{this.timestamp()} {this.channel()} {this.name()}: {this.text()}</div>
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
          <TextMessage key={i}
            insertedAt={message.inserted_at}
            channel={message.channel}
            game={message.game}
            name={message.name}
            message={message.message || message.text} />
        );
    }
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    let visibleBottom = this.terminal.scrollTop + this.terminal.clientHeight;
    this.triggerScroll = !(visibleBottom + 250 < this.terminal.scrollHeight);

    this.scrollToBottom();
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
