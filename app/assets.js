// One entry per menu item. Box colors match the item panel in each video
// (keep in sync with COLORS in tools/make-videos.sh).
const boxColors = [
  "#bd2828", "#bd6428", "#bda028", "#a0bd28", "#64bd28",
  "#28bd28", "#28bd64", "#28bda0", "#28a0bd", "#2864bd",
  "#2828bd", "#6428bd", "#a028bd", "#bd28a0", "#bd2864",
];
const videoSources = boxColors.map(function (_, i) {
  return "./videos/item" + String(i + 1).padStart(2, "0") + ".mp4";
});
