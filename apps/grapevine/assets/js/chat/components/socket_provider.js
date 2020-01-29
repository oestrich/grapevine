import React, {Fragment} from "react";
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {getSocketChannels} from "../redux/selectors";

class SocketProvider extends React.Component {
  getChildContext() {
    return {
      socket: this.props.socket,
    };
  }

  render() {
    return (
      <Fragment>{this.props.children}</Fragment>
    );
  }
}

SocketProvider.childContextTypes = {
  socket: PropTypes.object,
}

export {SocketProvider};
