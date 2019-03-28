import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';

import {getSocketLines} from "../redux/store";

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
        {_.map(lines, line => {
          return _.map(line, segment => {
            return (
              <AnsiText key={segment.id} text={segment} />
            );
          });
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

export default Terminal = connect(mapStateToProps)(Terminal);
