document.addEventListener("DOMContentLoaded", function () {
  var container = document.querySelector(".container");
  var boxes = [];
  var video = document.getElementById("myVideo");
  var currentBox = 0;

  // Play selected video
  function playVideo(vidIndex) {
    if (!video.paused) {
      return;
    }
    console.log("playing video " + vidIndex);
    video.src = videoSources[vidIndex];
    video.play();
  }

  // Stop all videos
  function stopVideo() {
    video.src = "";
    console.log("stopping video");
  }

  // Initialize matrix
  function setUpMatrix() {
    for (var i = 0; i < videoSources.length; i++) {
      var box = document.createElement("div");
      box.className = "box";
      box.tabIndex = i;
      box.style.backgroundColor = boxColors[i];
      box.textContent = String(i + 1).padStart(2, "0");
      container.appendChild(box);
      boxes.push(box);
    }
    boxes[currentBox].focus();
  }

  video.onended = function () {
    stopVideo();
  };

  // Shared navigation/selection logic used by both keyboard and IR remote
  function handleAction(action) {
    boxes[currentBox].blur();
    if (action === "right") {
      currentBox = (currentBox + 1) % boxes.length;
    } else if (action === "left") {
      currentBox = (currentBox - 1 + boxes.length) % boxes.length;
    } else if (action === "up") {
      currentBox = (currentBox - 5 + boxes.length) % boxes.length;
    } else if (action === "down") {
      currentBox = (currentBox + 5) % boxes.length;
    } else if (action === "stop") {
      console.log("x");
      stopVideo();
    } else if (action === "enter") {
      console.log("enter");
      playVideo(currentBox);
    }
    boxes[currentBox].focus();
    console.log(currentBox);
  }

  // Keyboard input
  var keyActions = {
    ArrowRight: "right",
    ArrowLeft: "left",
    ArrowUp: "up",
    ArrowDown: "down",
    Enter: "enter",
    x: "stop",
  };

  document.addEventListener("keydown", function (e) {
    var action = keyActions[e.key] || keyActions[e.key.toLowerCase()];
    if (action) {
      e.preventDefault();
      handleAction(action);
    }
  });

  // IR remote input (BrightSign RC-1002, NEC, via 3.5mm IR-in receiver)
  // NEC codes are 24 bits: bits 0-7 = button code, bits 8-23 = manufacturer code
  var IR_MANUFACTURER_CODE = 0x6f90;
  var irActions = {
    0x12: "up",
    0x13: "down",
    0x10: "left",
    0x11: "right",
    0x14: "enter", // OK
  };
  var irReceiver = null; // keep a reference so it isn't garbage collected

  function handleIrCode(code, isRepeat) {
    if (code >>> 8 !== IR_MANUFACTURER_CODE) {
      return;
    }
    var action = irActions[code & 0xff];
    // Holding a direction scrolls; holding OK does not re-trigger play
    if (action && !(isRepeat && action === "enter")) {
      handleAction(action);
    }
  }

  function setUpIrReceiver() {
    if (typeof BSIRReceiver === "undefined") {
      console.log("BSIRReceiver not available; IR remote disabled");
      return;
    }
    try {
      irReceiver = new BSIRReceiver("IR-in", "NEC");
      irReceiver.onremotedown = function (e) {
        console.log("IR down " + e.irType + " " + e.code);
        handleIrCode(e.code, false);
      };
      irReceiver.onremoterepeat = function (e) {
        handleIrCode(e.code, true);
      };
    } catch (err) {
      console.log("Failed to create BSIRReceiver: " + err);
    }
  }

  setUpMatrix();
  setUpIrReceiver();
});
