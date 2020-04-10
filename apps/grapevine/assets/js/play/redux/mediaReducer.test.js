import {Media} from "./mediaReducer";

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

describe ("media class - match filter", () => {
  test("matches based on key", () => {
    let media = new Media({key: "ambient"});
    expect(media.matchFilter({key: "ambient"})).toEqual(true);

    media = new Media({key: "ambient"});
    expect(media.matchFilter({key: "other"})).toEqual(false);
  });

  test("matches based on name", () => {
    let media = new Media({name: "file.mp3"});
    expect(media.matchFilter({name: "file.mp3"})).toEqual(true);

    media = new Media({name: "file.mp3"});
    expect(media.matchFilter({name: "other.mp3"})).toEqual(false);
  });

  test("matches based on type", () => {
    let media = new Media({type: "music"});
    expect(media.matchFilter({type: "music"})).toEqual(true);

    media = new Media({type: "music"});
    expect(media.matchFilter({type: "sound"})).toEqual(false);
  });

  test("matches based on tag", () => {
    let media = new Media({tag: "background"});
    expect(media.matchFilter({tag: "background"})).toEqual(true);

    media = new Media({tag: "background"});
    expect(media.matchFilter({tag: "foreground"})).toEqual(false);
  });

  test("matches based on priority", () => {
    let media = new Media({priority: 50});
    expect(media.matchFilter({priority: 50})).toEqual(true);

    media = new Media({priority: 50});
    expect(media.matchFilter({priority: 65})).toEqual(true);

    media = new Media({priority: 50});
    expect(media.matchFilter({priority: 25})).toEqual(false);
  });

  test("combination", () => {
  });
});
