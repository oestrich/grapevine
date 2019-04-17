import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';

import {
  getSettingsFont,
  getSettingsFontSize,
  getSocketLines
} from "../redux/store";

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
  const font = getSettingsFont(state);
  const fontSize = getSettingsFontSize(state);
  return {font, fontSize, lines};
};

export default Terminal = connect(mapStateToProps)(Terminal);
