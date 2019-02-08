import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {
  getPromptDisplayText,
  promptSetCurrentText,
  promptHistoryAdd,
  promptHistoryScrollBackward,
  promptHistoryScrollForward
} from "../redux/store";

class Prompt extends React.Component {
  constructor(props) {
    super(props);

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
        break;
      }
      case 38: { // up
        e.preventDefault();
        this.props.promptHistoryScrollBackward();
        this.shouldSelect = true;
        break;
      }
      case 40: { // down
        e.preventDefault();
        this.props.promptHistoryScrollForward();
        this.shouldSelect = true;
        break;
      }
    }
  }

  sendMessage() {
    const {socket} = this.context;
    socket.send(`${this.props.displayText}\n`);
    this.props.promptHistoryAdd();
    this.prompt.select();
  }

  onTextChange(e) {
    this.props.promptSetCurrentText(e.target.value);
  }

  componentDidUpdate() {
    if (this.shouldSelect) {
      this.shouldSelect = false;
      this.prompt.select();
    }
  }

  render() {
    let displayText = this.props.displayText;

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

let mapStateToProps = (state) => {
  let displayText = getPromptDisplayText(state);
  return {displayText};
};

export default Prompt = connect(mapStateToProps, {
  promptSetCurrentText,
  promptHistoryAdd,
  promptHistoryScrollBackward,
  promptHistoryScrollForward
})(Prompt);
