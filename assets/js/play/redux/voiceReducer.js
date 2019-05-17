import _ from "underscore";
import { createReducer } from "reduxsauce";

import {Types} from "./actions";

const INITITAL_STATE = {
  synthesisPresent: false,
  currentVoice: null,
  voices: [],
}

export const voiceSetVoice = (state, action) => {
  return {...state, currentVoice: action.voice};
}

export const voiceSetVoices = (state, action) => {
  return {...state, synthesisPresent: true, currentVoice: action.voices[0], voices: action.voices};
}

export const HANDLERS = {
  [Types.VOICE_SET_VOICES]: voiceSetVoices,
  [Types.VOICE_SET_VOICE]: voiceSetVoice,
}

export const voiceReducer = createReducer(INITITAL_STATE, HANDLERS);
