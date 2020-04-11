import {Filter, Media} from "./mediaReducer";

describe("filtering", () => {
  test("validates name", () => {
    let filter = new Filter({name: "file.mp3"});
    expect(filter.name).toEqual("file.mp3");

    filter = new Filter({name: "file.ogg"});
    expect(filter.name).toEqual(undefined);

    filter = new Filter({name: "anything else"});
    expect(filter.name).toEqual(undefined);
  });

  test("validates type", () => {
    let filter = new Filter({type: "music"});
    expect(filter.type).toEqual("music");

    filter = new Filter({type: "sound"});
    expect(filter.type).toEqual("sound");

    filter = new Filter({type: "anything else"});
    expect(filter.type).toEqual(undefined);
  });

  test("validates tag", () => {
    let filter = new Filter({tag: "combat"});
    expect(filter.tag).toEqual("combat");

    filter = new Filter({tag: 10});
    expect(filter.tag).toEqual(undefined);
  });

  test("validates priority", () => {
    let filter = new Filter({priority: 50});
    expect(filter.priority).toEqual(50);

    filter = new Filter({priority: 1});
    expect(filter.priority).toEqual(1);

    filter = new Filter({priority: -1});
    expect(filter.priority).toEqual(undefined);

    filter = new Filter({priority: "anything else"});
    expect(filter.priority).toEqual(undefined);
  });

  test("validates key", () => {
    let filter = new Filter({key: "a key"});
    expect(filter.key).toEqual("a key");

    filter = new Filter({key: 1});
    expect(filter.key).toEqual(undefined);
  });
});

describe("filters match", () => {
  test("matches based on key", () => {
    let filter = new Filter({key: "ambient"});
    expect(filter.matches(new Filter({key: "ambient"}))).toEqual(true);

    filter = new Filter({key: "ambient"});
    expect(filter.matches(new Filter({key: "other"}))).toEqual(false);
  });

  test("matches based on name", () => {
    let filter = new Filter({name: "file.mp3"});
    expect(filter.matches({name: "file.mp3"})).toEqual(true);

    filter = new Filter({name: "file.mp3"});
    expect(filter.matches({name: "other.mp3"})).toEqual(false);
  });

  test("matches based on type", () => {
    let filter = new Filter({type: "music"});
    expect(filter.matches({type: "music"})).toEqual(true);

    filter = new Filter({type: "music"});
    expect(filter.matches({type: "sound"})).toEqual(false);
  });

  test("matches based on tag", () => {
    let filter = new Filter({tag: "background"});
    expect(filter.matches({tag: "background"})).toEqual(true);

    filter = new Filter({tag: "background"});
    expect(filter.matches({tag: "foreground"})).toEqual(false);
  });

  test("matches based on priority", () => {
    let filter = new Filter({priority: 50});
    expect(filter.matches({priority: 50})).toEqual(true);

    filter = new Filter({priority: 50});
    expect(filter.matches({priority: 65})).toEqual(true);

    filter = new Filter({priority: 50});
    expect(filter.matches({priority: 25})).toEqual(false);
  });

  test("matches based on combinations", () => {
    let filter = new Filter({tag: "background", priority: 50});
    expect(filter.matches({tag: "background", priority: 65})).toEqual(true);

    filter = new Filter({type: "music", priority: 50});
    expect(filter.matches({type: "music", priority: 35})).toEqual(false);

    filter = new Filter({type: "music", priority: 50});
    expect(filter.matches({key: "background"})).toEqual(false);

    filter = new Filter({type: "music", priority: 50});
    expect(filter.matches({priority: 65})).toEqual(true);
  });
});

describe("media class - file url", () => {
  test("uses the default url to construct the url", () => {
    let media = new Media({name: "file.mp3"}, {url: "https://example.com/"});
    expect(media.url).toEqual("https://example.com/file.mp3");
  });

  test("includes a trailing slash automatically", () => {
    let media = new Media({name: "file.mp3"}, {url: "https://example.com"});
    expect(media.url).toEqual("https://example.com/file.mp3");
  });

  test("uses the specific url if provided", () => {
    let media = new Media({name: "file.mp3", url: "https://example.com"});
    expect(media.url).toEqual("https://example.com/file.mp3");
  });
});
