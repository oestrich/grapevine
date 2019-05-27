export class Line {
  constructor(sequences) {
    this.sequences = sequences;
  }

  last() {
    return _.last(this.sequences);
  }
}

class Sequence {
  constructor(opts) {
    if (opts) {
      if (opts.id !== null && opts.id !== undefined) {
        this.id = opts.id;
      }

      if (opts.color) {
        this.color = opts.color;
      }

      if (opts.backgroundColor) {
        this.backgroundColor = opts.backgroundColor;
      }

      if (opts.decorations) {
        this.decorations = opts.decorations;
      }
    }
  }

  includeDecoration(decoration) {
    return !!this.decorations && this.decorations.includes(decoration);
  }

  getOptions() {
    return {
      color: this.color,
      backgroundColor: this.backgroundColor,
      decorations: this.decorations,
    };
  }
}

export class EscapeSequence extends Sequence {
  constructor(text, opts) {
    super(opts);
    this.text = text;
  }
}

export class InputSequence extends Sequence {
  constructor(text, opts) {
    super(opts);

    this.text = text;
    this.color = "white";
    this.backgroundColor = "black";
    this.decorations = [];
    this.opts = opts;
  }

  getOptions() {
    return {
      color: this.opts.color,
      backgroundColor: this.opts.backgroundColor,
      decorations: this.opts.decorations,
    };
  }
}

export class ParseError extends Sequence {
  constructor(sequence, opts) {
    super(opts);
    this.sequence = sequence;
  }
}
