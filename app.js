const LOCAL_FAVORITES = Array.isArray(window.LIVING_ROOM_TV_FAVORITES)
  ? window.LIVING_ROOM_TV_FAVORITES
  : [];

const DASHBOARD_CONFIG = {
  rows: [
    {
      title: "Streaming",
      showCardSubtitles: false,
      items: [
        { title: "YouTube", subtitle: "Videos and live streams", initials: "YT", accent: "#d91f26", action: { type: "url", url: "https://www.youtube.com" } },
        { title: "Prime Video", subtitle: "Movies and shows", initials: "PV", accent: "#0578ff", action: { type: "url", url: "https://www.primevideo.com" } },
        { title: "Apple TV", subtitle: "Original series and movies", initials: "ATV", accent: "#d1d5db", action: { type: "url", url: "https://tv.apple.com" } },
        { title: "Hulu", subtitle: "Shows, movies, live TV", initials: "H", accent: "#1ce783", action: { type: "url", url: "https://www.hulu.com" } },
        { title: "Peacock", subtitle: "Series, sports, movies", initials: "P", accent: "#7c3aed", action: { type: "url", url: "https://www.peacocktv.com" } },
        { title: "Tubi", subtitle: "Free movies and shows", initials: "T", accent: "#f97316", action: { type: "url", url: "https://tubitv.com" } },
        { title: "Max", subtitle: "Films and series", initials: "M", accent: "#4f46e5", action: { type: "url", url: "https://www.max.com" } },
        { title: "Netflix", subtitle: "Movies and series", initials: "N", accent: "#b20710", action: { type: "url", url: "https://www.netflix.com" } },
        { title: "Disney+", subtitle: "Family favorites", initials: "D+", accent: "#1d4ed8", action: { type: "url", url: "https://www.disneyplus.com" } },
        { title: "Twitch", subtitle: "Live channels", initials: "TW", accent: "#9146ff", action: { type: "url", url: "https://www.twitch.tv" } }
      ]
    },
    {
      title: "Games",
      showCardSubtitles: false,
      items: [
        { title: "Steam", subtitle: "Games library", initials: "S", accent: "#2563eb", action: { type: "protocol", uri: "steam://open/bigpicture", message: "Opening Steam..." } },
        { title: "EA", subtitle: "Games library", initials: "EA", accent: "#ff4747", action: { type: "helper", action: "ea", message: "Opening EA..." } }
      ]
    },
    {
      title: "Internet",
      items: [
        { title: "Internet", subtitle: "Search and browse", initials: "I", accent: "#fbbc04", action: { type: "url", url: "https://www.google.com" } }
      ]
    },
    ...(LOCAL_FAVORITES.length ? [{
      title: "Favorites",
      showCardSubtitles: false,
      items: LOCAL_FAVORITES
    }] : []),
    {
      title: "Settings",
      items: [
        { title: "Sleep", subtitle: "Rest the display", initials: "SL", accent: "#64748b", action: { type: "helper", action: "sleep", message: "Requesting sleep...", recent: false } },
        { title: "Restart", subtitle: "Start fresh", initials: "R", accent: "#0ea5e9", action: { type: "helper", action: "restart", message: "Requesting restart...", confirm: true, confirmMessage: "Press again to restart.", recent: false } },
        { title: "Shutdown", subtitle: "Power off", initials: "SD", accent: "#ef4444", action: { type: "helper", action: "shutdown", message: "Requesting shutdown...", confirm: true, confirmMessage: "Press again to shut down.", recent: false } }
      ]
    }
  ]
};

const RECENTS_KEY = "livingRoomTv.recents";
const HELPER_PROTOCOL_BASE = "livingroomtv://action/";
const CONFIRMATION_TIMEOUT_MS = 7000;
let rowsEl;
let clockEl;
let todayEl;
let heroKickerEl;
let heroTitleEl;
let heroSubtitleEl;
let heroMarkEl;
let heroRecentsEl;
let navigationModel;
let toastTimer = 0;
let pendingConfirmation = null;

function initializeDashboard() {
  rowsEl = document.getElementById("rows");
  clockEl = document.getElementById("clock");
  todayEl = document.getElementById("today");
  heroKickerEl = document.getElementById("heroKicker");
  heroTitleEl = document.getElementById("heroTitle");
  heroSubtitleEl = document.getElementById("heroSubtitle");
  heroMarkEl = document.getElementById("heroMark");
  heroRecentsEl = document.getElementById("heroRecents");

  validateConfig(DASHBOARD_CONFIG);
  navigationModel = createNavigationModel(DASHBOARD_CONFIG);
  renderDashboard();
  updateTime();
  setInterval(updateTime, 1000);
  setFocus(0, 0);
}

function createNavigationModel(config) {
  return {
    focusArea: "rows",
    focusedRowIndex: 0,
    focusedCardByRow: config.rows.map(() => 0),
    focusedRecentIndex: 0,
    rows: config.rows.map((row) => ({
      title: row.title,
      showCardSubtitles: row.showCardSubtitles !== false,
      cards: row.items
    }))
  };
}

function validateConfig(config) {
  const supportedActionTypes = ["url", "protocol", "helper", "placeholder"];
  const supportedHelperActions = ["ping", "ea", "sleep", "restart", "shutdown"];

  if (!config || !Array.isArray(config.rows) || !config.rows.length) {
    throw new Error("Dashboard rows are missing.");
  }

  config.rows.forEach((row) => {
    if (!row.title || !Array.isArray(row.items) || !row.items.length) {
      throw new Error("A dashboard row is incomplete.");
    }

    row.items.forEach((item) => {
      if (!item.title || !item.subtitle || !item.initials || !item.accent || !item.action?.type) {
        throw new Error("A dashboard item is incomplete.");
      }

      if (!supportedActionTypes.includes(item.action.type)) {
        throw new Error(`Unsupported action type: ${item.action.type}`);
      }

      if (item.action.type === "url" && !item.action.url) {
        throw new Error(`Missing URL for ${item.title}.`);
      }

      if (item.action.type === "protocol" && !item.action.uri) {
        throw new Error(`Missing protocol URI for ${item.title}.`);
      }

      if (item.action.type === "helper" && !item.action.action) {
        throw new Error(`Missing helper action for ${item.title}.`);
      }

      if (item.action.type === "helper" && !supportedHelperActions.includes(item.action.action)) {
        throw new Error(`Unsupported helper action for ${item.title}.`);
      }
    });
  });
}

function renderDashboard() {
  rowsEl.innerHTML = navigationModel.rows.map((row, rowIndex) => {
    const cards = row.cards.map((item, colIndex) => `
      <button
        class="card"
        type="button"
        tabindex="-1"
        style="--accent: ${item.accent}"
        data-row="${rowIndex}"
        data-col="${colIndex}"
        aria-label="${item.title}">
        <span class="card-content">
          <span class="card-mark" aria-hidden="true">${item.initials}</span>
          <span>
            <span class="card-title">${item.title}</span>
            ${row.showCardSubtitles ? `<span class="card-subtitle">${item.subtitle}</span>` : ""}
          </span>
        </span>
      </button>
    `).join("");

    return `
      <section class="row" data-row-kind="${row.title.toLowerCase()}" aria-label="${row.title}">
        <h2 class="row-title">${row.title}</h2>
        <div class="rail">${cards}</div>
      </section>
    `;
  }).join("");

  document.querySelectorAll(".card").forEach((card) => {
    card.addEventListener("click", () => {
      const row = Number(card.dataset.row);
      const col = Number(card.dataset.col);
      setFocus(row, col);
      activateFocusedCard();
    });
  });
}

function getFocusedCard() {
  if (navigationModel.focusArea !== "rows") return null;

  const { rowIndex, cardIndex } = getFocusedPosition();

  return document.querySelector(`.card[data-row="${rowIndex}"][data-col="${cardIndex}"]`);
}

function getFocusedItem() {
  if (navigationModel.focusArea === "recents") {
    return getRecentItems()[navigationModel.focusedRecentIndex];
  }

  const { rowIndex, cardIndex } = getFocusedPosition();

  return navigationModel.rows[rowIndex]?.cards[cardIndex];
}

function getFocusedPosition() {
  const rowIndex = navigationModel.focusedRowIndex;

  return {
    rowIndex,
    cardIndex: navigationModel.focusedCardByRow[rowIndex]
  };
}

function setFocus(rowIndex, cardIndex) {
  const nextRowIndex = Math.max(0, Math.min(rowIndex, navigationModel.rows.length - 1));
  const maxCardIndex = navigationModel.rows[nextRowIndex].cards.length - 1;
  const nextCardIndex = Math.max(0, Math.min(cardIndex, maxCardIndex));

  navigationModel.focusArea = "rows";
  navigationModel.focusedRowIndex = nextRowIndex;
  navigationModel.focusedCardByRow[nextRowIndex] = nextCardIndex;

  clearVisualFocus();

  const focusedCard = getFocusedCard();
  focusedCard?.classList.add("is-focused");
  updateHero();
}

function setRecentFocus(recentIndex) {
  const recents = getRecentItems();

  if (!recents.length) return;

  navigationModel.focusArea = "recents";
  navigationModel.focusedRecentIndex = Math.max(0, Math.min(recentIndex, recents.length - 1));
  clearVisualFocus();
  getRecentPill(navigationModel.focusedRecentIndex)?.classList.add("is-focused");
  updateHero();
}

function clearVisualFocus() {
  document.querySelectorAll(".card, .hero-recent-item").forEach((item) => item.classList.remove("is-focused"));
}

// Horizontal movement owns only the rail's scrollLeft. It must never align the
// page vertically, especially in Chrome F11 fullscreen where viewport height
// changes can otherwise expose tiny browser-driven scroll adjustments.
function scrollRailToCard(rowIndex, colIndex) {
  const rail = getRowRail(rowIndex);
  const focusedCard = getCardElement(rowIndex, colIndex);

  if (!rail || !focusedCard) return;

  const cardCount = rail.querySelectorAll(".card").length;

  if (colIndex === 0) {
    rail.scrollLeft = 0;
    return;
  }

  const targetLeft = getRailTargetScrollLeft(rail, focusedCard, colIndex, cardCount);

  rail.scrollTo({ left: targetLeft, behavior: "smooth" });
}

function getRowRail(rowIndex) {
  return document.querySelectorAll(".rail")[rowIndex];
}

function getCardElement(rowIndex, colIndex) {
  return document.querySelector(`.card[data-row="${rowIndex}"][data-col="${colIndex}"]`);
}

function getRailTargetScrollLeft(rail, focusedCard, cardIndex, cardCount) {
  const padding = getRailSafePadding(rail);
  const maxScrollLeft = Math.max(0, rail.scrollWidth - rail.clientWidth);
  const cardLeft = focusedCard.offsetLeft;
  const cardRight = cardLeft + focusedCard.offsetWidth;

  if (cardIndex === cardCount - 1) {
    return clampScrollLeft(cardRight - rail.clientWidth + padding, maxScrollLeft);
  }

  const centeredLeft = cardLeft - (rail.clientWidth - focusedCard.offsetWidth) / 2;

  return clampScrollLeft(centeredLeft, maxScrollLeft);
}

function clampScrollLeft(value, maxScrollLeft) {
  return Math.max(0, Math.min(value, maxScrollLeft));
}

// Vertical alignment is intentionally isolated to Up/Down navigation. Left and
// Right never call this helper.
function alignRowVertically(rowIndex) {
  const row = document.querySelectorAll(".row")[rowIndex];

  if (!row) return;

  if (rowIndex === 0) {
    window.scrollTo({ top: 0, behavior: "smooth" });
    return;
  }

  const topOffset = Math.max(92, window.innerHeight * 0.14);
  const targetTop = window.scrollY + row.getBoundingClientRect().top - topOffset;

  window.scrollTo({ top: Math.max(0, targetTop), behavior: "smooth" });
}

function getRailSafePadding(rail) {
  const safeArea = rail ? getComputedStyle(rail).paddingLeft : "";

  return Number.parseFloat(safeArea) || 52;
}

function updateHero() {
  const item = getFocusedItem();
  const row = navigationModel.rows[navigationModel.focusedRowIndex];

  if (!item) return;

  document.documentElement.style.setProperty("--hero-accent", item.accent);
  document.documentElement.style.setProperty("--hero-accent-soft", `color-mix(in srgb, ${item.accent}, transparent 78%)`);
  heroKickerEl.textContent = navigationModel.focusArea === "recents" ? "Recently opened" : row.title;
  heroTitleEl.textContent = item.title;
  heroSubtitleEl.textContent = item.subtitle;
  heroMarkEl.textContent = item.initials;
  updateHeroRecents();
}

function updateHeroRecents() {
  const recents = getRecentItems();

  if (!recents.length) {
    heroRecentsEl.hidden = true;
    heroRecentsEl.replaceChildren();
    return;
  }

  heroRecentsEl.hidden = false;
  heroRecentsEl.replaceChildren(
    createHeroRecentLabel("Recently opened"),
    ...recents.map((recent, index) => createHeroRecentItem(recent, index))
  );

  if (navigationModel.focusArea === "recents") {
    getRecentPill(navigationModel.focusedRecentIndex)?.classList.add("is-focused");
  }
}

function createHeroRecentLabel(text) {
  const label = document.createElement("span");
  label.className = "hero-recent-label";
  label.textContent = text;
  return label;
}

function createHeroRecentItem(item, index) {
  const recent = document.createElement("button");
  recent.className = "hero-recent-item";
  recent.type = "button";
  recent.tabIndex = -1;
  recent.textContent = item.title;
  recent.setAttribute("aria-label", `Open ${item.title}`);
  recent.dataset.recentIndex = String(index);
  recent.style.setProperty("--accent", item.accent);
  recent.addEventListener("click", () => {
    setRecentFocus(index);
    activateItem(item);
  });
  return recent;
}

function getRecentItems() {
  return readRecents().slice(0, 3);
}

function getRecentPill(index) {
  return heroRecentsEl.querySelector(`.hero-recent-item[data-recent-index="${index}"]`);
}

function getNextFocusPosition(direction) {
  const { rowIndex, cardIndex } = getFocusedPosition();
  const rowCount = navigationModel.rows.length;
  const cardCount = navigationModel.rows[rowIndex].cards.length;

  if (direction === "up") {
    if (rowIndex === 0) {
      const recents = getRecentItems();

      if (!recents.length) return null;

      return {
        area: "recents",
        recentIndex: Math.min(navigationModel.focusedRecentIndex, recents.length - 1)
      };
    }

    return {
      area: "rows",
      rowIndex: rowIndex - 1,
      cardIndex: getRememberedColumnForRow(rowIndex - 1)
    };
  }

  if (direction === "down") {
    if (rowIndex === rowCount - 1) return null;
    return {
      area: "rows",
      rowIndex: rowIndex + 1,
      cardIndex: getRememberedColumnForRow(rowIndex + 1)
    };
  }

  if (direction === "left") {
    if (cardIndex === 0) return null;
    return { area: "rows", rowIndex, cardIndex: cardIndex - 1 };
  }

  if (direction === "right") {
    if (cardIndex === cardCount - 1) return null;
    return { area: "rows", rowIndex, cardIndex: cardIndex + 1 };
  }

  return null;
}

function getRememberedColumnForRow(rowIndex) {
  const maxCardIndex = navigationModel.rows[rowIndex].cards.length - 1;

  return Math.max(0, Math.min(navigationModel.focusedCardByRow[rowIndex], maxCardIndex));
}

// Navigation is driven only by the logical row/card model. Scrolling follows
// this focus state; scroll position never decides where focus moves.
function moveFocus(direction) {
  clearPendingConfirmation();

  if (navigationModel.focusArea === "recents") {
    moveRecentFocus(direction);
    return;
  }

  const nextPosition = getNextFocusPosition(direction);

  if (!nextPosition) return;

  if (direction === "up" && nextPosition.area === "recents") {
    setRecentFocus(nextPosition.recentIndex);
    window.scrollTo({ top: 0, behavior: "smooth" });
    return;
  }

  const isHorizontalMove = direction === "left" || direction === "right";

  setFocus(nextPosition.rowIndex, nextPosition.cardIndex);

  if (isHorizontalMove) {
    scrollRailToCard(nextPosition.rowIndex, nextPosition.cardIndex);
    return;
  }

  scrollRailToCard(nextPosition.rowIndex, nextPosition.cardIndex);
  alignRowVertically(nextPosition.rowIndex);
}

function moveRecentFocus(direction) {
  const recents = getRecentItems();

  if (!recents.length) {
    setFocus(0, navigationModel.focusedCardByRow[0]);
    scrollRailToCard(0, navigationModel.focusedCardByRow[0]);
    alignRowVertically(0);
    return;
  }

  if (direction === "left") {
    if (navigationModel.focusedRecentIndex === 0) return;
    setRecentFocus(navigationModel.focusedRecentIndex - 1);
    return;
  }

  if (direction === "right") {
    if (navigationModel.focusedRecentIndex === recents.length - 1) return;
    setRecentFocus(navigationModel.focusedRecentIndex + 1);
    return;
  }

  if (direction === "down") {
    const targetColumn = getRememberedColumnForRow(0);
    setFocus(0, targetColumn);
    scrollRailToCard(0, targetColumn);
    alignRowVertically(0);
  }
}

function activateFocusedCard() {
  const item = getFocusedItem();

  if (!item) return;

  activateItem(item);
}

function activateItem(item) {
  markActivatingItem(item);

  if (item.action.confirm && !consumeConfirmation(item)) {
    requestConfirmation(item);
    return;
  }

  if (item.action.type === "url") {
    saveRecent(item);
    showToast(`Opening ${item.title}...`);
    window.location.href = item.action.url;
    return;
  }

  if (item.action.type === "protocol") {
    saveRecent(item);
    showToast(item.action.message || `Opening ${item.title}...`);
    window.location.href = item.action.uri;
    return;
  }

  if (item.action.type === "helper") {
    if (item.action.recent !== false) {
      saveRecent(item);
    }

    showToast(item.action.message || `Opening ${item.title}...`);
    window.location.href = `${HELPER_PROTOCOL_BASE}${encodeURIComponent(item.action.action)}`;
    return;
  }

  if (item.action.type === "placeholder") {
    showToast(item.action.message);
  }
}

function requestConfirmation(item) {
  pendingConfirmation = {
    key: getActionKey(item),
    expiresAt: Date.now() + CONFIRMATION_TIMEOUT_MS
  };

  markConfirmingItem(item);
  showToast(item.action.confirmMessage || `Select ${item.title} again to confirm.`);
}

function consumeConfirmation(item) {
  if (!pendingConfirmation) return false;

  const isConfirmed = pendingConfirmation.key === getActionKey(item) && pendingConfirmation.expiresAt > Date.now();

  pendingConfirmation = null;
  clearConfirmingItems();

  return isConfirmed;
}

function clearPendingConfirmation() {
  pendingConfirmation = null;
  clearConfirmingItems();
}

function markConfirmingItem(item) {
  clearConfirmingItems();

  document.querySelectorAll(".card, .hero-recent-item").forEach((element) => {
    if (element.textContent.trim().includes(item.title)) {
      element.classList.add("is-confirming");
    }
  });
}

function clearConfirmingItems() {
  document.querySelectorAll(".is-confirming").forEach((item) => item.classList.remove("is-confirming"));
}

function markActivatingItem(item) {
  document.querySelectorAll(".card, .hero-recent-item").forEach((element) => {
    const label = element.getAttribute("aria-label");

    if (label !== item.title && label !== `Open ${item.title}`) return;

    element.classList.add("is-activating");
    element.addEventListener("animationend", () => element.classList.remove("is-activating"), { once: true });
  });
}

function getActionKey(item) {
  return `${item.title}:${item.action.type}:${item.action.action || item.action.uri || item.action.url || ""}`;
}

function readRecents() {
  try {
    return JSON.parse(localStorage.getItem(RECENTS_KEY) || "[]");
  } catch {
    return [];
  }
}

function saveRecent(item) {
  const recentItem = {
    title: item.title,
    subtitle: item.subtitle,
    initials: item.initials,
    accent: item.accent,
    action: item.action
  };
  const deduped = readRecents().filter((recent) => recent.title !== item.title);

  localStorage.setItem(RECENTS_KEY, JSON.stringify([recentItem, ...deduped].slice(0, 5)));
}

function showToast(message) {
  let toast = document.querySelector(".toast");

  if (!toast) {
    toast = document.createElement("div");
    toast.className = "toast";
    toast.setAttribute("role", "status");
    document.body.appendChild(toast);
  }

  toast.textContent = message;
  toast.classList.add("is-visible");
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => toast.classList.remove("is-visible"), 2400);
}

function updateTime() {
  const now = new Date();
  clockEl.textContent = now.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit"
  });
  todayEl.textContent = now.toLocaleDateString([], {
    weekday: "long",
    month: "long",
    day: "numeric"
  });
}

document.addEventListener("keydown", (event) => {
  const directionByKey = {
    ArrowLeft: "left",
    ArrowRight: "right",
    ArrowUp: "up",
    ArrowDown: "down"
  };

  if (directionByKey[event.key]) {
    event.preventDefault();
    moveFocus(directionByKey[event.key]);
  }

  if (event.key === "Enter") {
    event.preventDefault();
    activateFocusedCard();
  }

  if (event.key === "Escape" || event.key === "Backspace") {
    event.preventDefault();
    clearPendingConfirmation();
    setFocus(0, navigationModel.focusedCardByRow[0]);
    scrollRailToCard(0, navigationModel.focusedCardByRow[0]);
    alignRowVertically(0);
  }
});

try {
  initializeDashboard();
} catch (error) {
  window.showLivingRoomTvSafeMode?.();
}
