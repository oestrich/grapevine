import React from 'react';

export default class RedirectURI extends React.Component {
  constructor() {
    super();

    this.state = {
      formClass: "hidden",
      uri: "",
    }

    this.showForm = this.showForm.bind(this);
    this.onURIChange = this.onURIChange.bind(this);
  }

  showForm(e) {
    e.preventDefault();
    this.setState({
      formClass: "",
    });
  }

  onURIChange(e) {
    this.setState({uri: e.target.value});
  }

  render() {
    let action = this.props.action;
    let formClass = this.state.formClass;
    let csrfToken = document.querySelector("meta[name='csrf-token']").content;
    let uri = this.state.uri;

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
                  <label>URI</label>
                  <input type="text" name="redirect_uri[uri]" onChange={this.onURIChange} value={uri} className="form-control" />
                </div>

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
