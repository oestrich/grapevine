import _ from "underscore";
import React from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {
  Creators
} from "../redux/actions";

import {
  getSocketOAuth,
} from "../redux/store";

class OAuthAuthorization extends React.Component {
  constructor(props) {
    super(props);

    this.authorize = this.authorize.bind(this);
    this.close = this.close.bind(this);
  }

  authorize() {
    this.props.socketOAuthClose();
    const {socket} = this.context;
    socket.event("oauth", {state: "accept"});
  }

  close() {
    this.props.socketOAuthClose();
    const {socket} = this.context;
    socket.event("oauth", {state: "reject"});
  }

  render() {
    if (this.props.status !== "authorizing") {
      return null;
    }

    let game = this.props.game;
    let scopes = this.props.scopes;

    return (
      <section className="client-modal">
        <nav className="header">
          <h3 className="name">Authorize</h3>

          <div className="actions">
            <i className="close fa fa-times" onClick={this.close}></i>
          </div>
        </nav>

        <div className="body">
          <p className="lead">{game} wants to connect with the following permissions:</p>

          <ul>
            {_.map(scopes, (scope) => {
              return (
                <li key={scope}>
                  {scope}
                </li>
              );
            })}
          </ul>

          <div className="btn btn-primary btn-block btn-flat" onClick={this.authorize}>
            Authorize
          </div>

          <div className="btn btn-secondary btn-block btn-flat" onClick={this.close}>
            Deny
          </div>
          </div>
      </section>
    );
  }
}

OAuthAuthorization.contextTypes = {
  socket: PropTypes.object,
};

let mapStateToProps = (state) => {
  let oauth = getSocketOAuth(state);
  if (oauth) {
    return {status: oauth.status, scopes: oauth.scopes};
  } else {
    return {};
  }
};

OAuthAuthorization = connect(mapStateToProps, {
  socketOAuthClose: Creators.socketOAuthClose,
})(OAuthAuthorization);

export {
  OAuthAuthorization,
};
