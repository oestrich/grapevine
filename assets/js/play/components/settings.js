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
  getVoiceSynthesisPresent,
  getVoiceCurrentVoice,
  getVoiceVoices,
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

class FontSettings extends React.Component {
  constructor(props) {
    super(props);

    this.fontOnChange = this.fontOnChange.bind(this);
    this.fontSizeOnChange = this.fontSizeOnChange.bind(this);
  }

  fontOnChange(e) {
    this.props.setFont(e.target.value);
  }

  fontSizeOnChange(e) {
    this.props.setFontSize(e.target.value);
  }

  render() {
    let font = this.props.font;
    let fontSize = this.props.fontSize;

    return (
      <Fragment>
        <h4>Text</h4>

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
      </Fragment>
    );
  }
}

class SynthesisSettings extends React.Component {
  constructor(props) {
    super(props);

    this.voiceOnChange = this.voiceOnChange.bind(this);
  }

  voiceOnChange(e) {
    this.props.setVoice(e.target.value);
  }

  render() {
    if (!this.props.synthesisPresent) {
      return null;
    }

    let currentVoice = this.props.currentVoice;
    let voices = this.props.voices;

    return (
      <Fragment>
        <h4>Speech Synthesis (Beta)</h4>

        <div className="form-group">
          <label htmlFor="settings-voice">Voice</label>
          <select id="settings-vocie" className="form-control" value={currentVoice} onChange={this.voiceOnChange}>
            {_.map(voices, voice => {
              return (
                <option key={voice}>{voice}</option>
              );
            })}
          </select>
        </div>
      </Fragment>
    );
  }
}

class Settings extends React.Component {
  constructor(props) {
    super(props);

    this.close = this.close.bind(this);
  }

  close() {
    this.props.settingsToggle();
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

        <div className="body">
          <FontSettings />

          <SynthesisSettings />
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

  return {font, fontSize};
};

FontSettings = connect(mapStateToProps, {
  setFont: Creators.settingsSetFont,
  setFontSize: Creators.settingsSetFontSize,
})(FontSettings);

mapStateToProps = (state) => {
  let open = getSettingsOpen(state);
  return {open};
};

Settings = connect(mapStateToProps, {
  settingsToggle: Creators.settingsToggle,
})(Settings);

SettingsToggle = connect(mapStateToProps, {
  settingsToggle: Creators.settingsToggle,
})(SettingsToggle);

mapStateToProps = (state) => {
  let synthesisPresent = getVoiceSynthesisPresent(state);
  let currentVoice = getVoiceCurrentVoice(state);
  let voices = getVoiceVoices(state);

  return {synthesisPresent, currentVoice, voices};
};

SynthesisSettings = connect(mapStateToProps, {
  setVoice: Creators.voiceSetVoice,
})(SynthesisSettings);

export {
  Settings,
  SettingsToggle,
};
