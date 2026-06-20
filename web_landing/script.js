document.addEventListener("DOMContentLoaded", () => {
    // Initialize Lucide Icons
    lucide.createIcons();

    // ==========================================
    // 1. BOOT LOADER SEQUENCER
    // ==========================================
    const bootLoader = document.getElementById("bootLoader");
    const progressBar = document.getElementById("bootProgressBar");
    const percentageText = document.getElementById("bootPercentage");
    const logsContainer = document.getElementById("bootLogs");

    const bootLogsList = [
        "> INITIALIZING CAMERA RECONSTRUCTION PROTOCOL...",
        "> ESTIMATING VIEWPOINT VECTOR PERSPECTIVE [OK]",
        "> CONNECTING GPS COORDINATES FOR Munysari ROUTE...",
        "> CACHING GEMS: Birthi, Chandak, Sasling...",
        "> BOOTING RESHOT AI ENGINE V1.0.3 COMPLETED."
    ];

    let progress = 0;
    let logIndex = 0;

    const runLoader = setInterval(() => {
        progress += Math.floor(Math.random() * 8) + 4;
        if (progress > 100) progress = 100;

        progressBar.style.width = `${progress}%`;
        percentageText.textContent = `${progress.toString().padStart(2, '0')}%`;

        // Periodically inject log statements
        if (progress > (logIndex + 1) * 20 && logIndex < bootLogsList.length) {
            const p = document.createElement("p");
            p.textContent = bootLogsList[logIndex];
            logsContainer.appendChild(p);
            logIndex++;
        }

        if (progress === 100) {
            clearInterval(runLoader);
            setTimeout(() => {
                // Fade out loader
                gsap.to(bootLoader, {
                    opacity: 0,
                    y: -50,
                    duration: 0.6,
                    ease: "power2.inOut",
                    onComplete: () => {
                        bootLoader.style.display = "none";
                        animateHeroWindows(); // Trigger entrance animations
                    }
                });
            }, 600);
        }
    }, 80);

    // ==========================================
    // 2. HERO WINDOWS ENTRANCE ANIMATIONS
    // ==========================================
    function animateHeroWindows() {
        // Animate title elements
        gsap.from(".hero-title .glitch-text", {
            x: -100,
            opacity: 0,
            duration: 0.8,
            ease: "back.out(1.7)"
        });
        gsap.from(".hero-title br + span", {
            x: 100,
            opacity: 0,
            duration: 0.8,
            delay: 0.2,
            ease: "back.out(1.7)"
        });
        gsap.from(".hero-subtitle, .hero-ctas", {
            y: 40,
            opacity: 0,
            duration: 0.6,
            delay: 0.4,
            stagger: 0.1
        });

        // Entrance for interactive windows
        gsap.from("#windowCamera", {
            scale: 0.3,
            rotation: -10,
            opacity: 0,
            duration: 1,
            delay: 0.6,
            ease: "elastic.out(1, 0.6)"
        });

        gsap.from("#windowScore", {
            scale: 0.3,
            rotation: 12,
            opacity: 0,
            duration: 1,
            delay: 0.8,
            ease: "elastic.out(1, 0.6)"
        });

        gsap.from("#windowRadar", {
            scale: 0.3,
            rotation: -5,
            opacity: 0,
            duration: 1,
            delay: 1,
            ease: "elastic.out(1, 0.6)"
        });
    }

    // ==========================================
    // 3. CUSTOM VIEWPORT CURSOR
    // ==========================================
    const cursor = document.getElementById("customCursor");
    let mouseX = 0, mouseY = 0;
    let cursorX = 0, cursorY = 0;

    window.addEventListener("mousemove", (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

    // Custom cursor lerp logic
    function updateCursor() {
        const dx = mouseX - cursorX;
        const dy = mouseY - cursorY;
        cursorX += dx * 0.2;
        cursorY += dy * 0.2;
        cursor.style.left = `${cursorX}px`;
        cursor.style.top = `${cursorY}px`;
        requestAnimationFrame(updateCursor);
    }
    updateCursor();

    // Hover interactive state management
    const interactiveElements = document.querySelectorAll("a, button, input, .location-card, .retro-window, .slider-control input");
    interactiveElements.forEach(el => {
        el.addEventListener("mouseenter", () => {
            document.body.classList.add("hovering-interactive");
        });
        el.addEventListener("mouseleave", () => {
            document.body.classList.remove("hovering-interactive");
        });
    });

    // ==========================================
    // 4. GSAP DRAGGABLE RETRO WINDOWS
    // ==========================================
    if (typeof Draggable !== "undefined") {
        Draggable.create(".draggable", {
            handle: ".window-header",
            bounds: ".hero-interactive",
            onPress: function() {
                // Raise the clicked window's z-index hierarchy
                document.querySelectorAll(".retro-window").forEach(w => w.style.zIndex = 10);
                this.target.style.zIndex = 30;
            }
        });
    }

    // ==========================================
    // 5. INTERACTIVE POSE SIMULATOR
    // ==========================================
    const userSkeleton = document.getElementById("userSkeleton");
    const posSlider = document.getElementById("posSlider");
    const tiltSlider = document.getElementById("tiltSlider");
    const scaleSlider = document.getElementById("scaleSlider");

    const simPercentage = document.getElementById("simPercentage");
    const simProgressBar = document.getElementById("simProgressBar");
    const tiltMatchVal = document.getElementById("tiltMatchVal");
    const scaleMatchVal = document.getElementById("scaleMatchVal");

    const alignmentStatus = document.getElementById("alignmentStatus");
    const alignmentArrow = document.getElementById("alignmentArrow");
    const btnCapture = document.getElementById("btnCapture");
    const captureBtnText = document.getElementById("captureBtnText");

    function updatePoseSimulation() {
        const posX = parseInt(posSlider.value); // 0 to 100. Perfect = 50
        const tiltY = parseInt(tiltSlider.value); // -30 to 30. Perfect = 0
        const scaleVal = parseInt(scaleSlider.value); // 50 to 150. Perfect = 100

        // 1. Transform the SVG Skeleton
        // Center of user skeleton in coordinates is roughly (100, 100)
        // Offset mapping:
        const xTranslate = (posX - 50) * 1.5; // Translate range
        const scaleFactor = scaleVal / 100;
        
        userSkeleton.style.transformOrigin = "100px 100px";
        userSkeleton.style.transform = `translate(${xTranslate}px, 0px) rotate(${tiltY}deg) scale(${scaleFactor})`;

        // 2. Alignment calculations
        const xDiff = Math.abs(posX - 50); // 0 (best) to 50 (worst)
        const tiltDiff = Math.abs(tiltY - 0); // 0 (best) to 30 (worst)
        const scaleDiff = Math.abs(scaleVal - 100); // 0 (best) to 50 (worst)

        // Map individual accuracy
        const xAccuracy = Math.max(0, 100 - (xDiff * 2));
        const tiltAccuracy = Math.max(0, 100 - (tiltDiff * 3.33));
        const scaleAccuracy = Math.max(0, 100 - (scaleDiff * 2));

        // Display individual outputs
        tiltMatchVal.textContent = `${Math.round(tiltAccuracy)}%`;
        scaleMatchVal.textContent = `${Math.round(scaleAccuracy)}%`;

        // Calculate weighted overall similarity
        const overallSim = Math.round((xAccuracy * 0.4) + (tiltAccuracy * 0.3) + (scaleAccuracy * 0.3));

        // Update overall percentage on display
        simPercentage.textContent = `${overallSim}%`;
        simProgressBar.style.width = `${overallSim}%`;

        // 3. UI alignment statuses
        if (overallSim < 60) {
            simPercentage.className = "stat-number font-retro";
            simProgressBar.className = "stat-bar-inner";
            userSkeleton.classList.remove("aligned");
            alignmentStatus.className = "hud-status";
            alignmentStatus.textContent = `ALIGNMENT POOR (${overallSim}%)`;
            btnCapture.classList.add("disabled");
            captureBtnText.textContent = "LOCKED (GET 90%+)";
        } else if (overallSim < 90) {
            simPercentage.className = "stat-number font-retro";
            simProgressBar.className = "stat-bar-inner";
            userSkeleton.classList.remove("aligned");
            alignmentStatus.className = "hud-status";
            alignmentStatus.textContent = `ALIGNING... (${overallSim}%)`;
            btnCapture.classList.add("disabled");
            captureBtnText.textContent = "LOCKED (GET 90%+)";
        } else {
            // Perfect range >= 90%
            simPercentage.className = "stat-number font-retro aligned";
            simProgressBar.className = "stat-bar-inner aligned";
            userSkeleton.classList.add("aligned");
            alignmentStatus.className = "hud-status aligned";
            alignmentStatus.textContent = `MATCH PERFECT (${overallSim}%)`;
            btnCapture.classList.remove("disabled");
            captureBtnText.textContent = "CAPTURE RESHOT!";
        }

        // Live Guidance Arrows based on current offsets
        if (posX < 45) {
            alignmentArrow.textContent = "← MOVE RIGHT";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else if (posX > 55) {
            alignmentArrow.textContent = "MOVE LEFT →";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else if (tiltY > 5) {
            alignmentArrow.textContent = "🔄 ROTATE CCW";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else if (tiltY < -5) {
            alignmentArrow.textContent = "🔄 ROTATE CW";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else if (scaleVal < 90) {
            alignmentArrow.textContent = "🔎 STEP CLOSER";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else if (scaleVal > 110) {
            alignmentArrow.textContent = "🔎 STEP BACK";
            alignmentArrow.style.color = "var(--hot-pink)";
        } else {
            alignmentArrow.textContent = "🎯 HOLD STEADY!";
            alignmentArrow.style.color = "var(--lime-green)";
        }
    }

    // Attach listeners to sliders
    posSlider.addEventListener("input", updatePoseSimulation);
    tiltSlider.addEventListener("input", updatePoseSimulation);
    scaleSlider.addEventListener("input", updatePoseSimulation);

    // Initial trigger
    updatePoseSimulation();

    // ==========================================
    // 5B. WEBCAM INTERACTIVE STREAMING
    // ==========================================
    async function initWebcam(videoEl, placeholderEl, btnEl) {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: "user" },
                audio: false
            });
            videoEl.srcObject = stream;
            videoEl.classList.remove("hidden");
            if (placeholderEl) placeholderEl.classList.add("hidden");
            if (btnEl) btnEl.classList.add("hidden");
            return true;
        } catch (err) {
            console.error("Camera access error:", err);
            alert("Could not access your camera device. Please grant permission in your browser or check another app using it.");
            return false;
        }
    }

    const btnActivateHeroCam = document.getElementById("btnActivateHeroCam");
    const heroWebcam = document.getElementById("heroWebcam");
    const heroPlaceholder = document.getElementById("heroPlaceholder");

    if (btnActivateHeroCam) {
        btnActivateHeroCam.addEventListener("click", () => {
            initWebcam(heroWebcam, heroPlaceholder, btnActivateHeroCam);
        });
    }

    const btnActivateSimCam = document.getElementById("btnActivateSimCam");
    const simWebcam = document.getElementById("simWebcam");
    const simPlaceholder = document.getElementById("simPlaceholder");

    let isSimWebcamActive = false;
    if (btnActivateSimCam) {
        btnActivateSimCam.addEventListener("click", async () => {
            const success = await initWebcam(simWebcam, simPlaceholder, btnActivateSimCam);
            isSimWebcamActive = success;
        });
    }

    // ==========================================
    // 5C. PHOTO CAPTURE AND SUCCESS MODAL
    // ==========================================
    const capturedModal = document.getElementById("capturedModal");
    const btnCloseModal = document.getElementById("btnCloseModal");
    const capturedImage = document.getElementById("capturedImage");
    const modalScoreVal = document.getElementById("modalScoreVal");
    const captureCanvas = document.getElementById("captureCanvas");

    btnCapture.addEventListener("click", () => {
        if (!btnCapture.classList.contains("disabled")) {
            // Trigger Confetti
            if (typeof confetti !== "undefined") {
                confetti({
                    particleCount: 150,
                    spread: 80,
                    origin: { y: 0.6 },
                    colors: ['#CEFF05', '#FF2E9B', '#FFFFFF', '#000000']
                });
            }

            // Animate flash effect
            gsap.to(".camera-canvas-wrapper", {
                backgroundColor: "#fff",
                duration: 0.05,
                yoyo: true,
                repeat: 3,
                onComplete: () => {
                    document.querySelector(".camera-canvas-wrapper").style.backgroundColor = "#000";
                }
            });

            // Set final matching score
            const scoreText = simPercentage.textContent;
            modalScoreVal.textContent = scoreText;

            // Render live canvas snapshot or fallback placeholder
            if (isSimWebcamActive && simWebcam.videoWidth) {
                const ctx = captureCanvas.getContext("2d");
                captureCanvas.width = simWebcam.videoWidth;
                captureCanvas.height = simWebcam.videoHeight;
                ctx.drawImage(simWebcam, 0, 0, captureCanvas.width, captureCanvas.height);
                capturedImage.src = captureCanvas.toDataURL("image/png");
                capturedImage.style.transform = "scaleX(-1)"; // Keep it mirrored
            } else {
                capturedImage.src = "pose_art.png";
                capturedImage.style.transform = "none";
            }

            // Open popup
            capturedModal.classList.remove("hidden");
        }
    });

    if (btnCloseModal) {
        btnCloseModal.addEventListener("click", () => {
            capturedModal.classList.add("hidden");
        });
    }

    capturedModal.addEventListener("click", (e) => {
        if (e.target === capturedModal) {
            capturedModal.classList.add("hidden");
        }
    });

    // ==========================================
    // 6. LOCATION DISCOVERY ENGINE INTERACTIVE
    // ==========================================
    const locationCards = document.querySelectorAll(".location-card");
    const lblLat = document.getElementById("lblLat");
    const lblLng = document.getElementById("lblLng");
    const recreationTips = document.getElementById("recreationTips");
    const radarMarker = document.querySelector(".target-marker");

    const coordinatesData = {
        birthi: {
            lat: "30.1254",
            lng: "80.1425",
            tips: [
                "📸 Recommended lens: Ultra-wide (16-24mm)",
                "👤 Subject positioning: Center lower third",
                "⏰ Best light: 3:00 PM - 5:00 PM"
            ],
            markerPos: { top: "35%", left: "60%" }
        },
        chandak: {
            lat: "29.5985",
            lng: "80.2033",
            tips: [
                "📸 Recommended lens: Portrait (35-50mm)",
                "👤 Subject positioning: Left rule of thirds line",
                "⏰ Best light: Golden hour (5:30 PM - 6:30 PM)"
            ],
            markerPos: { top: "60%", left: "40%" }
        },
        sasling: {
            lat: "29.6241",
            lng: "80.1255",
            tips: [
                "📸 Recommended lens: Standard zoom (24-70mm)",
                "👤 Subject positioning: Sitting on lower right rock",
                "⏰ Best light: Overcast or midday for forest shade"
            ],
            markerPos: { top: "25%", left: "30%" }
        }
    };

    locationCards.forEach(card => {
        card.addEventListener("click", () => {
            // Remove active status from all cards
            locationCards.forEach(c => c.classList.remove("active"));
            card.classList.add("active");

            // Extract target location details
            const locId = card.getAttribute("data-id");
            const data = coordinatesData[locId];

            if (data) {
                // Animate numbers and coordinate boxes changes
                gsap.to(lblLat, {
                    textContent: data.lat,
                    duration: 0.4,
                    snap: { textContent: 0.0001 }
                });
                gsap.to(lblLng, {
                    textContent: data.lng,
                    duration: 0.4,
                    snap: { textContent: 0.0001 }
                });

                // Update advice tips list
                recreationTips.innerHTML = "";
                data.tips.forEach(tip => {
                    const li = document.createElement("li");
                    li.textContent = tip;
                    recreationTips.appendChild(li);
                });

                // Animate radar target marker on custom map HUD grid
                gsap.to(radarMarker, {
                    top: data.markerPos.top,
                    left: data.markerPos.left,
                    duration: 0.6,
                    ease: "back.out(1.5)"
                });
            }
        });
    });
});
