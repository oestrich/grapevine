import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {
  Creators
} from "../redux/actions";

import {
  getSettingsFont,
  getSettingsFontSize,
  getSettingsOpen,
} from "../redux/store";

const fontSizes = [10, 12, 14, 16, 18, 20, 22, 24];

class SettingsToggle extends React.Component {
  constructor(props) {
    super(props);

    this.toggleOpen = this.toggleOpen.bind(this);
  }

  toggleOpen() {
    this.props.settingsToggle();
  }

  render() {
    return (
      <i className="settings-toggle fa fa-cog" onClick={this.toggleOpen}></i>
    );
  }
}

class Settings extends React.Component {
  constructor(props) {
    super(props);

    this.close = this.close.bind(this);
    this.fontOnChange = this.fontOnChange.bind(this);
    this.fontSizeOnChange = this.fontSizeOnChange.bind(this);
  }

  close() {
    this.props.settingsToggle();
  }

  fontOnChange(e) {
    this.props.setFont(e.target.value);
  }

  fontSizeOnChange(e) {
    this.props.setFontSize(e.target.value);
  }

  render() {
    if (!this.props.open) {
      return null;
    }

    let font = this.props.font;
    let fontSize = this.props.fontSize;

    return (
      <section className="settings">
        <nav className="header">
          <h3 className="name">Settings</h3>

          <div className="actions">
            <i className="close fa fa-times" onClick={this.close}></i>
          </div>
        </nav>

        <div className="form-group">
          <label htmlFor="settings-font">Font</label>
          <select id="settings-font" className="form-control" value={font} onChange={this.fontOnChange}>
            <option>Monaco</option>
            <option>Inconsolata</option>
            <option>Fira Mono</option>
            <option>Roboto Mono</option>
            <option>Source Code Pro</option>
            <option>Courier New</option>
          </select>
        </div>

        <div className="form-group">
          <label htmlFor="settings-font-size">Font Size</label>
          <select id="settings-font-size" className="form-control" value={fontSize} onChange={this.fontSizeOnChange}>
            {_.map(fontSizes, size => {
              return (
                <option key={size}>{size}</option>
              );
            })}
          </select>
        </div>
      </section>
    );
  }
}

Settings.contextTypes = {
  socket: PropTypes.object,
};

let mapStateToProps = (state) => {
  let font = getSettingsFont(state);
  let fontSize = getSettingsFontSize(state);
  let open = getSettingsOpen(state);

  return {font, fontSize, open};
};

Settings = connect(mapStateToProps, {
  setFont: Creators.settingsSetFont,
  setFontSize: Creators.settingsSetFontSize,
  settingsToggle: Creators.settingsToggle,
})(Settings);

SettingsToggle = connect(mapStateToProps, {
  settingsToggle: Creators.settingsToggle,
})(SettingsToggle);

export {
  Settings,
  SettingsToggle,
};
