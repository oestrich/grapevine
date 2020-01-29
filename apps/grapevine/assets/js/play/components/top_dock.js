import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

export default class TopDock extends React.Component {
  render() {
    return (
      <div className="top-dock">
        {this.props.children}
      </div>
    );
  }
}
