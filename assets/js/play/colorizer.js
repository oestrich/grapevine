import {combineAndParseSegments, detectLines} from "./colorizer/parser";

/**
 * Parse new text and combine it with the previous line
 *
 * Merges the new sequences with the last line and detects the resulting lines.
 */
export const parse = (currentLine, text) => {
  let sequences = [];
  if (currentLine) {
    sequences = currentLine.sequences;
  }

  sequences = combineAndParseSegments(sequences, text);
  return detectLines(sequences);
};
