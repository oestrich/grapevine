import _ from "underscore";
import React, {Fragment} from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';

import {AnsiText} from "./terminal";

import {
  getModals,
} from "../redux/store";

class ModalBody extends React.Component {
  render() {
    return (
      <div className="body">
        <pre>
          {_.map(this.props.segments, (segment, i) => {
            return (<AnsiText key={i} text={segment} />);
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
    console.log("close the modal");
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

    return (
      <section className="game-modal" ref={(el) => { this.section = el; }} onMouseMove={this.onMouseMove}>
        <nav className={headerClass} onMouseDown={this.onMouseDown} onMouseUp={this.onMouseUp}>
          <h3 className="name">{this.props.title}</h3>

          <div className="actions">
            <i className="close fa fa-times" onClick={this.close}></i>
          </div>
        </nav>

        <ModalBody segments={this.props.segments} />
      </section>
    );
  }
}

class Modals extends React.Component {
  render() {
    console.log(this.props.modals);

    return (
      <div className="modals">
        {_.map(this.props.modals, (modal) => {
          return (
            <Modal key={modal.key} title={modal.title} segments={modal.segments} />
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
