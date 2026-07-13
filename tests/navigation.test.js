const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const projectRoot = path.resolve(__dirname, "..");
const appSource = fs.readFileSync(path.join(projectRoot, "app.js"), "utf8");
const styleSource = fs.readFileSync(path.join(projectRoot, "style.css"), "utf8");
const indexSource = fs.readFileSync(path.join(projectRoot, "index.html"), "utf8");
const ignoreSource = fs.readFileSync(path.join(projectRoot, ".gitignore"), "utf8");
const favoritesExampleSource = fs.readFileSync(path.join(projectRoot, "favorites.local.example.js"), "utf8");

function createAppContext(favorites = []) {
  const scrollCalls = [];
  const context = vm.createContext({
    console,
    document: {
      addEventListener() {},
      querySelector() { return null; },
      querySelectorAll() { return []; },
      documentElement: { style: { setProperty() {} } }
    },
    localStorage: { getItem() { return "[]"; }, setItem() {} },
    navigator: {},
    requestAnimationFrame() {},
    setInterval() {},
    getComputedStyle() { return { paddingLeft: "72px" }; },
    window: {
      innerHeight: 1080,
      scrollY: 240,
      scrollTo(options) { scrollCalls.push(options); },
      matchMedia() { return { matches: true }; },
      setTimeout() { return 1; }
    }
  });

  context.window.LIVING_ROOM_TV_FAVORITES = favorites;
  vm.runInContext(appSource, context);
  return { context, scrollCalls };
}

function setRows(context, focusedRowIndex, columns, rowLengths) {
  const rows = rowLengths.map((length) => ({ cards: Array.from({ length }, () => ({})) }));
  vm.runInContext(
    `navigationModel = ${JSON.stringify({
      focusArea: "rows",
      focusedRowIndex,
      focusedCardByRow: columns,
      focusedRecentIndex: 0,
      rows
    })}`,
    context
  );
}

test("vertical row movement restores each destination row's remembered column", () => {
  const { context } = createAppContext();
  setRows(context, 1, [2, 3, 1], [9, 5, 4]);

  const up = vm.runInContext('getNextFocusPosition("up")', context);
  const down = vm.runInContext('getNextFocusPosition("down")', context);

  assert.deepEqual({ ...up }, { area: "rows", rowIndex: 0, cardIndex: 2 });
  assert.deepEqual({ ...down }, { area: "rows", rowIndex: 2, cardIndex: 1 });
});

test("remembered destination state clamps only when the row is now shorter", () => {
  const { context } = createAppContext();
  setRows(context, 0, [7, 7, 0], [9, 2, 1]);

  const down = vm.runInContext('getNextFocusPosition("down")', context);

  assert.deepEqual({ ...down }, { area: "rows", rowIndex: 1, cardIndex: 1 });
});

test("Recent pills and Streaming restore their independent remembered positions", () => {
  const { context } = createAppContext();
  setRows(context, 0, [0, 0], [9, 2]);
  vm.runInContext(`
    navigationModel.focusedCardByRow[0] = 0;
    navigationModel.focusedRecentIndex = 1;
    getRecentItems = () => [{}, {}, {}];
  `, context);

  const up = vm.runInContext('getNextFocusPosition("up")', context);

  assert.deepEqual({ ...up }, { area: "recents", recentIndex: 1 });

  vm.runInContext(`
    navigationModel.focusArea = "recents";
    navigationModel.focusedRecentIndex = 2;
    setFocus = (rowIndex, cardIndex) => {
      navigationModel.focusArea = "rows";
      navigationModel.focusedRowIndex = rowIndex;
      navigationModel.focusedCardByRow[rowIndex] = cardIndex;
    };
    scrollRailToCard = () => {};
    alignRowVertically = () => {};
    moveRecentFocus("down");
  `, context);

  assert.equal(vm.runInContext("navigationModel.focusedCardByRow[0]", context), 0);
});

test("recent-pill horizontal movement does not request vertical scrolling", () => {
  const { context, scrollCalls } = createAppContext();
  vm.runInContext(`
    navigationModel = { focusArea: "recents", focusedRecentIndex: 0 };
    getRecentItems = () => [{}, {}];
    setRecentFocus = (index) => { navigationModel.focusedRecentIndex = index; };
    moveRecentFocus("right");
  `, context);

  assert.equal(vm.runInContext("navigationModel.focusedRecentIndex", context), 1);
  assert.equal(scrollCalls.length, 0);
});

test("dashboard consumes Steam-translated keyboard input and never polls Gamepad input", () => {
  const assertSteamTranslatedInput = (source) => {
    assert.doesNotMatch(source, /navigator\.getGamepads|gamepad\.axes|gamepad\.buttons|pollGamepad/);
    assert.match(source, /document\.addEventListener\("keydown"/);
    assert.match(source, /ArrowLeft:\s*"left"/);
    assert.match(source, /ArrowRight:\s*"right"/);
    assert.match(source, /ArrowUp:\s*"up"/);
    assert.match(source, /ArrowDown:\s*"down"/);
    assert.match(source, /event\.key === "Enter"[\s\S]*?activateFocusedCard\(\)/);
  };

  assert.doesNotThrow(() => assertSteamTranslatedInput(appSource));
  assert.throws(() => assertSteamTranslatedInput(`
    function pollGamepad() {
      const horizontal = gamepad.axes[0] || 0;
      if (horizontal < -0.55) moveFocus("left");
      requestAnimationFrame(pollGamepad);
    }
  `));
});

test("hero keeps fixed outer zones and centers recents in the flexible middle column", () => {
  const assertHeroTracks = (tracks) => {
    assert.match(tracks, /^minmax\(0, 320px\) minmax\(340px, 1fr\) 190px$/);
  };
  const middleOffsetFromHeroCenter = (leftTrack, artTrack) => (leftTrack - artTrack) / 2;
  const heroTracks = styleSource.match(/\.hero\s*\{[\s\S]*?grid-template-columns:\s*([^;]+);/)?.[1].trim();

  assert.doesNotThrow(() => assertHeroTracks("minmax(0, 320px) minmax(340px, 1fr) 190px"));
  assert.throws(() => assertHeroTracks("minmax(0, 1.02fr) minmax(340px, 0.86fr) minmax(160px, 0.34fr)"));
  assert.throws(() => assertHeroTracks("1fr minmax(340px, 560px) 1fr"));
  assert.deepEqual(
    [1440, 2560, 3840].map(() => middleOffsetFromHeroCenter(320, 190)),
    [65, 65, 65]
  );
  assert.ok(middleOffsetFromHeroCenter(420, 165) - middleOffsetFromHeroCenter(320, 190) >= 60);
  assertHeroTracks(heroTracks);
  assert.match(styleSource, /\.hero-recents\s*\{[\s\S]*?grid-column:\s*2;/);
  assert.match(styleSource, /\.hero-recents\s*\{[\s\S]*?justify-self:\s*center;/);
  assert.match(styleSource, /\.hero-copy\s*\{[\s\S]*?grid-column:\s*1;/);
  assert.match(styleSource, /\.hero-art\s*\{[\s\S]*?grid-column:\s*3;/);
  assert.match(styleSource, /--hero-height:\s*clamp\(270px, 20vh, 340px\);/);
  assert.match(styleSource, /\.hero\s*\{[\s\S]*?height:\s*var\(--hero-height\);/);
  assert.match(styleSource, /\.hero\s*\{[\s\S]*?column-gap:\s*clamp\(34px, 3\.6vw, 88px\);/);
  assert.match(styleSource, /\.hero\s*\{[\s\S]*?padding:\s*clamp\(24px, 2vw, 36px\) var\(--page-safe-area\);/);
});

test("premium presentation contracts use shared tokens without widening page overflow", () => {
  const requiredTokens = [
    "--page-safe-area",
    "--hero-height",
    "--row-spacing",
    "--card-width",
    "--card-height",
    "--card-radius",
    "--focus-scale",
    "--focus-brightness",
    "--unfocused-opacity",
    "--hero-artwork-opacity",
    "--card-shadow",
    "--motion-fast",
    "--motion-standard",
    "--launch-feedback-duration",
    "--ease-premium",
    "--type-hero",
    "--ambient-glow-strength",
    "--surface-opacity",
    "--shadow-depth",
    "--text-primary",
    "--text-muted"
  ];
  const assertPresentationContract = (source) => {
    const bodyBlock = source.match(/body\s*\{([^}]*)\}/)?.[1] || "";

    requiredTokens.forEach((token) => assert.match(source, new RegExp(`${token}:`)));
    assert.match(source, /\.tv-shell\s*\{[\s\S]*?width:\s*100%;/);
    assert.match(source, /@property --hero-accent/);
    assert.match(source, /@media \(prefers-reduced-motion: reduce\)/);
    assert.match(source, /\.row\[data-row-kind="settings"\]/);
    assert.doesNotMatch(source, /\.tv-shell\s*\{[\s\S]*?--content-width/);
    assert.doesNotMatch(bodyBlock, /overflow-x:\s*(?:auto|scroll)/);
  };

  assert.doesNotThrow(() => assertPresentationContract(styleSource));
  assert.throws(() => assertPresentationContract(`
    :root { --page-safe-area: 50px; }
    body { overflow-x: scroll; }
    .tv-shell { width: 1840px; }
  `));
  assert.match(appSource, /data-row-kind="\$\{row\.title\.toLowerCase\(\)\}"/);
  assert.match(appSource, /getComputedStyle\(rail\)\.paddingLeft/);
});

test("configured apps keep initials fallbacks and accept only local logo assets", () => {
  const rows = JSON.parse(JSON.stringify(vm.runInNewContext("DASHBOARD_CONFIG.rows", {
    DASHBOARD_CONFIG: vm.runInContext("DASHBOARD_CONFIG", createAppContext().context)
  })));
  const assertAssetContract = (configuredRows) => {
    configuredRows.flatMap((row) => row.items).forEach((item) => {
      assert.match(item.initials, /\S/);

      if (!item.logo) return;

      assert.doesNotMatch(item.logo, /^(?:https?:|data:|\/|\\)/i);
      assert.doesNotMatch(item.logo, /\.\.[/\\]/);
      assert.ok(fs.existsSync(path.join(projectRoot, item.logo)), `Missing local logo: ${item.logo}`);
    });
  };

  assert.doesNotThrow(() => assertAssetContract(rows));
  assert.throws(() => assertAssetContract([{ items: [{ initials: "", logo: "https://example.com/logo.svg" }] }]));
});

test("card descriptions are configuration-driven and redundant entertainment copy is hidden", () => {
  const { context } = createAppContext();
  const subtitleRules = JSON.parse(JSON.stringify(vm.runInContext(`
    DASHBOARD_CONFIG.rows.map((row) => ({ title: row.title, showCardSubtitles: row.showCardSubtitles !== false }))
  `, context)));

  assert.deepEqual(subtitleRules, [
    { title: "Streaming", showCardSubtitles: false },
    { title: "Games", showCardSubtitles: false },
    { title: "Internet", showCardSubtitles: true },
    { title: "Settings", showCardSubtitles: true }
  ]);
  assert.match(appSource, /row\.showCardSubtitles \? `<span class="card-subtitle">/);
});

test("local Favorites load before the dashboard without placing private data in tracked config", () => {
  const sampleFavorites = [{
    title: "Local Example",
    subtitle: "Personal",
    initials: "LE",
    accent: "#64748b",
    action: { type: "url", url: "https://example.test/local" }
  }];
  const { context } = createAppContext(sampleFavorites);
  const rows = JSON.parse(JSON.stringify(vm.runInContext(
    `DASHBOARD_CONFIG.rows.map((row) => ({ title: row.title, items: row.items }))`,
    context
  )));
  const favorites = rows.find((row) => row.title === "Favorites");

  assert.deepEqual(favorites.items, sampleFavorites);
  assert.ok(rows.findIndex((row) => row.title === "Favorites") < rows.findIndex((row) => row.title === "Settings"));
  assert.match(indexSource, /<script src="favorites\.local\.js"><\/script>\s*<script src="app\.js"><\/script>/);
  assert.match(ignoreSource, /^favorites\.local\.js$/m);
  assert.match(favoritesExampleSource, /window\.LIVING_ROOM_TV_FAVORITES\s*=\s*\[/);
  const exampleUrls = [...favoritesExampleSource.matchAll(/https:\/\/[^"']+/g)].map((match) => match[0]);
  assert.ok(exampleUrls.length > 0);
  exampleUrls.forEach((url) => assert.match(url, /^https:\/\/example\.com\//));
});

test("dashboard remains usable when no local Favorites file values are available", () => {
  const { context } = createAppContext();
  assert.equal(vm.runInContext(
    `DASHBOARD_CONFIG.rows.some((row) => row.title === "Favorites")`,
    context
  ), false);
});

test("launch feedback is immediate, non-blocking, and does not import browser bookmarks", () => {
  const activateItemSource = appSource.match(/function activateItem\(item\) \{[\s\S]*?\n\}/)?.[0] || "";
  const assertNoBookmarkImport = (source) => {
    assert.doesNotMatch(source, /chrome\.bookmarks|browser\.bookmarks|Bookmarks API/);
  };

  assert.match(activateItemSource, /markActivatingItem\(item\)/);
  assert.match(activateItemSource, /showToast\(`Opening \$\{item\.title\}\.\.\.`\)/);
  assert.doesNotMatch(activateItemSource, /setTimeout|await|Promise/);
  assert.match(styleSource, /animation:\s*activation-feedback var\(--launch-feedback-duration\)/);
  assert.doesNotThrow(() => assertNoBookmarkImport(appSource));
  assert.throws(() => assertNoBookmarkImport("chrome.bookmarks.getTree()"));
});

test("launch configuration uses Big Picture and user-facing EA copy", () => {
  const { context } = createAppContext();
  const games = JSON.parse(JSON.stringify(vm.runInContext(
    `DASHBOARD_CONFIG.rows.find((row) => row.title === "Games").items.map((item) => ({
      title: item.title,
      uri: item.action.uri,
      message: item.action.message
    }))`,
    context
  )));

  assert.deepEqual(
    games.map((item) => ({ ...item })),
    [
      { title: "Steam", uri: "steam://open/bigpicture", message: "Opening Steam..." },
      { title: "EA", message: "Opening EA..." }
    ]
  );
});

test("regression assertions reject stale navigation and launch controls", () => {
  const assertVerticalTarget = (target) => {
    assert.deepEqual(target, { area: "rows", rowIndex: 1, cardIndex: 3 });
  };
  const assertLaunchTarget = (target) => {
    assert.equal(target.uri, "steam://open/bigpicture");
    assert.equal(target.eaMessage, "Opening EA...");
  };

  assert.doesNotThrow(() => assertVerticalTarget({ area: "rows", rowIndex: 1, cardIndex: 3 }));
  assert.throws(() => assertVerticalTarget({ area: "rows", rowIndex: 1, cardIndex: 0 }));
  assert.doesNotThrow(() => assertLaunchTarget({ uri: "steam://open/bigpicture", eaMessage: "Opening EA..." }));
  assert.throws(() => assertLaunchTarget({ uri: "steam://open/main", eaMessage: "Requesting EA..." }));
});
