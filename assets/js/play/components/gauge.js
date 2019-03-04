import React from "react";
import {connect} from 'react-redux';

import {getSocketGMCP} from "../redux/store";

class Gauge extends React.Component {
  render() {
    let {name, message, value, max, color} = this.props.gauge;

    let data = this.props.gmcp[message];

    if (data) {
      let currentValue = data[value];
      let maxValue = data[max];

      if (currentValue == undefined || maxValue == undefined) {
        return null;
      }

      let width = currentValue / maxValue * 100;

      let className = `gauge ${color}`;

      return (
        <div className={className}>
          <div className="gauge-bar" style={{width: `${width}%`}} />
          <span>{currentValue}/{maxValue} {name}</span>
        </div>
      );
    } else {
      return null;
    }
  }
}

let mapStateToProps = (state) => {
  const gmcp = getSocketGMCP(state);
  return {gmcp};
};

export default Gauge = connect(mapStateToProps)(Gauge);
