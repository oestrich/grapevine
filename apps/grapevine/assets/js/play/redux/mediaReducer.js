import {Howl, Howler} from 'howler';
import {createReducer} from "reduxsauce";
import _ from "underscore";

import {Types} from "./actions";

export class Player {
  constructor() {
    this.activeMedia = [];
  }

  play(media) {
    _.each(this.activeMedia, (activeMedia) => {
      if (activeMedia.key == media.key) {
        activeMedia.stop();
      }
    });

    this.activeMedia = _.reject(this.activeMedia, (activeMedia) => {
      return activeMedia.key == media.key;
    });

    media.play();

    this.activeMedia.push(media);
  }

  stop(filter) {
    _.filter(this.activeMedia, (activeMedia) => {
      return activeMedia.matchFilter(filter);
    }).map((media) => {
      media.stop()
    });

    this.activeMedia = _.reject(this.activeMedia, (activeMedia) => {
      return !activeMedia.isPlaying();
    });
  }
}

const baseUrl = (attrs, defaults) => {
  let url;

  if ("url" in attrs) {
    url = attrs.url;
  } else if ("url" in defaults) {
    url = defaults.url;
  }

  if (url && !url.endsWith("/")) {
    url = url + "/";
  }

  return url;
}

export class Media {
  constructor(attrs, defaults = {}) {
    this.type = attrs.type;
    this.key = attrs.key;
    this.priority = attrs.priority;
    this.tag = attrs.tag;
    this.name = attrs.name;

    this.url = baseUrl(attrs, defaults) + attrs.name;

    this.howler = new Howl({
      src: [this.url],
      html5: true
    });
  }

  isPlaying() {
    return this.howler.playing();
  }

  play() {
    console.log("playing");
    this.howler.play();
  }

  matchFilter(filter) {
    let matchKeys = ["type", "name", "tag", "key"];

    matchKeys = _.filter(matchKeys, (key) => {
      return key in filter;
    });

    let matchedKeys = _.all(matchKeys, (key) => {
      return filter[key] == this[key];
    });

    return matchedKeys && this.priorityMatch(filter);
  }

  priorityMatch(filter) {
    if (!filter.priority) {
      return true;
    }

    if (!this.priority) {
      return false;
    }

    if (this.priority <= filter.priority) {
      return true;
    }

    return false;
  }

  stop() {
    console.log("stopping");
    this.howler.stop();
  }
}

const INITIAL_STATE = {
  defaults: {},
  player: new Player(),
}

export const mediaReceiveGMCP = (state, action) => {
  let key;

  switch (action.message) {
    case "Client.Media.Default":
      return {...state, defaults: action.data};

    case "Client.Media.Play":
      console.log("Want to play music...");
      console.log(action);

      let media = new Media(action.data, state.defaults);

      state.player.play(media);

      return state;

    case "Client.Media.Stop":
      state.player.stop(action.data);
      return state;

    default:
      return state;
  }
};

export const HANDLERS = {
  [Types.SOCKET_RECEIVE_GMCP]: mediaReceiveGMCP,
}

export const mediaReducer = createReducer(INITIAL_STATE, HANDLERS);
