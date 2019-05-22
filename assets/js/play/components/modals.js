import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {Line} from "./terminal";

import {
  Creators
} from "../redux/actions";

import {
  getModals,
} from "../redux/store";

class ModalBody extends React.Component {
  render() {
    return (
      <div className="body">
        <pre>
          {_.map(this.props.lines, (line, i) => {
            return (<Line key={i} sequences={line.sequences} />);
          })}
        </pre>
      </div>
    );
  }
}

class Modal extends React.Component {
  constructor(props) {
    super(props);

    this.close = this.close.bind(this);
    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);
    this.onMouseMove = this.onMouseMove.bind(this);

    this.state = {
      dragging: false,
    };
  }

  close() {
    let modal = this.props.modal;
    this.props.modalsClose(modal.key);
  }

  onMouseDown(e) {
    e.preventDefault();
    this.setState({
      currentX: e.clientX,
      currentY: e.clientY,
      dragging: true,
    });
  }

  onMouseUp(e) {
    e.preventDefault();
    this.setState({dragging: false});
  }

  onMouseMove(e) {
    e.preventDefault();

    if (this.state.dragging) {
      let newY = this.state.currentY - e.clientY;
      let newX = this.state.currentX - e.clientX;
      this.section.style.top = `${this.section.offsetTop - newY}px`;
      this.section.style.left = `${this.section.offsetLeft - newX}px`;
      this.setState({
        currentX: e.clientX,
        currentY: e.clientY,
      });
    }
  }

  render() {
    let headerClass = "header";

    if (this.state.dragging) {
      headerClass += " dragging";
    }

    let modal = this.props.modal;

    return (
      <section className="game-modal" ref={(el) => { this.section = el; }} onMouseMove={this.onMouseMove}>
        <nav className={headerClass} onMouseDown={this.onMouseDown} onMouseUp={this.onMouseUp}>
          <h3 className="name">{modal.title}</h3>

          <div className="actions">
            <i className="close fa fa-times" onClick={this.close}></i>
          </div>
        </nav>

        <ModalBody lines={modal.lines} />
      </section>
    );
  }
}

Modal = connect((state) => { return {}; }, {
  modalsClose: Creators.modalsClose,
})(Modal);

class Modals extends React.Component {
  render() {
    return (
      <div className="modals">
        {_.map(this.props.modals, (modal) => {
          return (
            <Modal key={modal.key} modal={modal} />
          );
        })}
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  let modals = getModals(state);
  return {modals};
};

Modals = connect(mapStateToProps, {})(Modals);

export default Modals;
