import React from 'react';
import {connect} from 'react-redux';

import {getSocketConnected} from "../redux/selectors";

class ConnectionStatus extends React.Component {
  connectionClassName() {
    if (this.props.connected) {
      return "green";
    } else {
      return "red";
    }
  }

  connectionTitle() {
    if (this.props.connected) {
      return `Connected to Grapevine`;
    } else {
      return "Disconnected";
    }
  }

  render() {
    return (
      <div className="connection">
        <i className={`fa fa-lock ${this.connectionClassName()}`} title={this.connectionTitle()} />
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const connected = getSocketConnected(state);
  return {connected};
};

ConnectionStatus = connect(mapStateToProps)(ConnectionStatus);

export {ConnectionStatus};
