import _ from "underscore";
import React from "react";
import {connect} from 'react-redux';

import {getSocketGMCP} from "../redux/store";
import Gauge from "./gauge";

class Gauges extends React.Component {
  gaugesEmpty() {
    let gauges = this.props.gauges;
    return gauges.length == 0;
  }

  dataEmpty() {
    let gmcp = this.props.gmcp;
    return Object.entries(gmcp).length === 0 && gmcp.constructor === Object;
  }

  render() {
    let gauges = this.props.gauges;

    if (this.gaugesEmpty() || this.dataEmpty()) {
      return null;
    }

    return (
      <div className="gauges">
        {_.map(gauges, (gauge, i) => {
          return (
            <Gauge gauge={gauge} key={i} />
          );
        })}
      </div>
    );
  }
}

let mapStateToProps = (state) => {
  const gmcp = getSocketGMCP(state);
  return {gmcp};
};

export default Gauges = connect(mapStateToProps)(Gauges);
