import React from 'react';

export default class Connection extends React.Component {
  constructor() {
    super();

    this.state = {
      formClass: "hidden",
      type: "web",
      url: "",
      host: "",
      port: "",
    }

    this.showForm = this.showForm.bind(this);
    this.onTypeChange = this.onTypeChange.bind(this);
    this.onURLChange = this.onURLChange.bind(this);
    this.onHostChange = this.onHostChange.bind(this);
    this.onPortChange = this.onPortChange.bind(this);
  }

  showForm(e) {
    e.preventDefault();
    this.setState({
      formClass: "",
    });
  }

  onTypeChange(e) {
    this.setState({type: e.target.value});
  }

  onURLChange(e) {
    this.setState({url: e.target.value});
  }

  onHostChange(e) {
    this.setState({host: e.target.value});
  }

  onPortChange(e) {
    this.setState({port: e.target.value});
  }

  renderUrl() {
    if (this.state.type != "web") {
      return null;
    }

    let url = this.state.url;

    return (
      <div className="form-group">
        <label>URL</label>
        <input type="text" name="connection[url]" onChange={this.onURLChange} value={url} className="form-control" />
      </div>
    );
  }

  renderHost() {
    if (this.state.type == "web") {
      return null;
    }

    let host = this.state.host;

    return (
      <div className="form-group">
        <label>Host</label>
        <input type="text" name="connection[host]" onChange={this.onHostChange} value={host} className="form-control" />
      </div>
    );
  }

  renderPort() {
    if (this.state.type == "web") {
      return null;
    }

    let port = this.state.port;

    return (
      <div className="form-group">
        <label>Port</label>
        <input type="number" name="connection[port]" onChange={this.onPortChange} value={port} className="form-control" />
      </div>
    );
  }

  render() {
    let action = this.props.action;
    let formClass = this.state.formClass;
    let csrfToken = document.querySelector("meta[name='csrf-token']").content;
    let type = this.state.type;

    return (
      <div className="add">
        <a href="#" className="btn btn-flat" onClick={this.showForm}>
          <i className="fa fa-plus"></i> Add
        </a>
        <div className={formClass}>
          <div className="card mb-3 mt-3">
            <div className="card-body">
              <form action={action} method="POST">
                <input type="hidden" name="_csrf_token" value={csrfToken} />
                <div className="form-group">
                  <label>Type</label>
                  <select value={type} onChange={this.onTypeChange} name="connection[type]" className="form-control">
                    <option>web</option>
                    <option>telnet</option>
                    <option>secure telnet</option>
                  </select>
                </div>

                {this.renderUrl()}
                {this.renderHost()}
                {this.renderPort()}

                <div className="form-group">
                  <input type="submit" value="Add" className="btn btn-primary" />
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    );
  }
}
