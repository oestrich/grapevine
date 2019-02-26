import React from 'react';
import {connect} from 'react-redux';

import {getSocketConnectionState, getSocketConnection} from "../redux/store";

class ConnectionStatus extends React.Component {
  connectionClassName() {
    if (this.props.connected) {
      return "green";
    } else {
      return "red";
    }
  }

  connectionTitle() {
    let connection = this.props.connection;

    if (this.props.connected && connection) {
      return `Connected to - ${connection.host}:${connection.port}`;
    } else {
      return "Disconnected";
    }
  }

  connectionIcon() {
    let connection = this.props.connection;

    if (connection && connection.type === "secure telnet") {
      return "fa-lock";
    } else {
      return "fa-circle";
    }
  }

  render() {
    return (
      <div className="connection">
        <i className={`fa ${this.connectionIcon()} ${this.connectionClassName()}`} title={this.connectionTitle()} />
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const connected = getSocketConnectionState(state);
  const connection = getSocketConnection(state);
  return {connected, connection};
};

export default ConnectionStatus = connect(mapStateToProps)(ConnectionStatus);
