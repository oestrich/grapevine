import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';

import {
  getSettingsFont,
  getSettingsFontSize,
  getSocketLines
} from "../redux/store";

export class AnsiText extends React.Component {
  textStyle(sequence) {
    let style = {};

    if (sequence.backgroundColor) {
      style.backgroundColor = sequence.backgroundColor;
    }

    if (sequence.color) {
      style.color = sequence.color;
    }

    if (sequence.decoration == "bold") {
      style.fontWeight = "bolder";
    }

    return style;
  }

  render() {
    let segment = this.props.text;

    if (segment.text === undefined) {
      return null;
    }

    return (
      <span style={this.textStyle(segment)}>{segment.text}</span>
    );
  }
}

export class Line extends React.Component {
  render() {
    let sequences = this.props.sequences;

    return sequences.map((sequence) => {
      return (
        <AnsiText key={sequence.id} text={sequence} />
      );
    });
  }
}

class Terminal extends React.Component {
  constructor(props) {
    super(props);

    this.triggerScroll = true;
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
    let lines = this.props.lines;

    let fontFamily = this.props.font;
    let fontSize = this.props.fontSize;

    const style = {
      fontFamily: `${fontFamily}, monospace`,
      fontSize
    };

    return (
      <div ref={el => { this.terminal = el; }} className="terminal" style={style}>
        {_.map(lines, line => {
          return (
            <Line key={line.id} sequences={line.sequences} />
          );
        })}
        <div ref={el => { this.el = el; }} />
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const lines = getSocketLines(state);
  const font = getSettingsFont(state);
  const fontSize = getSettingsFontSize(state);
  return {font, fontSize, lines};
};

export default Terminal = connect(mapStateToProps)(Terminal);
