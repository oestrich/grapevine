import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

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

export default Prompt;
