/**
 * Presentation Mode Controller
 * Created: October 15, 2025
 * Purpose: Full-screen slideshow system for ACC AI Committee presentation
 * Features: Keyboard navigation, progress tracking, presenter notes
 */

class PresentationMode {
    constructor() {
        this.slides = [];
        this.currentSlide = 0;
        this.isPresenting = false;
        this.presenterNotesVisible = false;

        // Configuration
        this.config = {
            transitionDuration: 600, // ms
            autoHideControls: 3000, // ms (hide controls after 3 seconds of inactivity)
            enablePresenterNotes: true
        };

        // Track mouse movement for auto-hide controls
        this.lastMouseMove = Date.now();
        this.controlsHidden = false;

        this.init();
    }

    init() {
        console.log('🎬 Presentation Mode: Initializing...');
        this.detectSlides();
        this.setupUI();
        this.setupKeyboardControls();
        this.setupMouseControls();
        console.log(`✅ Presentation Mode: Ready (${this.slides.length} slides detected)`);
    }

    detectSlides() {
        // Auto-detect sections as slides
        const sections = document.querySelectorAll('section, .slide, [data-slide]');

        if (sections.length === 0) {
            // Fallback: Create slides from main content sections
            console.warn('⚠️ No explicit slides found. Using heuristic detection...');

            // Detect major sections: header, summary cards, main sections
            const header = document.querySelector('header');
            const summaryCards = document.querySelector('.summary-cards');
            const highlightBoxes = document.querySelectorAll('.highlight-box');
            const mainSections = document.querySelectorAll('main > section, main > div > section');

            // Create slide wrappers
            if (header) this.slides.push({ element: header, title: 'Title Slide' });
            if (summaryCards) this.slides.push({ element: summaryCards, title: 'Key Metrics' });

            highlightBoxes.forEach((box, index) => {
                const title = box.querySelector('h3, h2')?.textContent || `Slide ${this.slides.length + 1}`;
                this.slides.push({ element: box, title });
            });

            mainSections.forEach((section, index) => {
                const title = section.querySelector('h2, h3')?.textContent || `Slide ${this.slides.length + 1}`;
                this.slides.push({ element: section, title });
            });
        } else {
            sections.forEach((section, index) => {
                const title = section.getAttribute('data-slide-title') ||
                             section.querySelector('h1, h2, h3')?.textContent ||
                             `Slide ${index + 1}`;
                this.slides.push({
                    element: section,
                    title,
                    notes: section.getAttribute('data-presenter-notes') || ''
                });
            });
        }

        console.log(`📊 Detected ${this.slides.length} slides`);
    }

    setupUI() {
        // Create presentation container
        const presContainer = document.createElement('div');
        presContainer.id = 'presentation-container';
        presContainer.className = 'presentation-mode';
        presContainer.style.display = 'none';

        // Create progress indicator
        const progressBar = document.createElement('div');
        progressBar.className = 'presentation-progress';
        progressBar.innerHTML = `
            <div class="progress-bar">
                <div class="progress-fill" id="progressFill"></div>
            </div>
            <div class="progress-text" id="progressText">Slide 1 of ${this.slides.length}</div>
        `;

        // Create navigation controls
        const controls = document.createElement('div');
        controls.className = 'presentation-controls';
        controls.innerHTML = `
            <button class="control-btn" id="prevSlide" title="Previous (← or Backspace)">
                ← Previous
            </button>
            <button class="control-btn" id="slideNumber" title="Current slide">
                1 / ${this.slides.length}
            </button>
            <button class="control-btn" id="nextSlide" title="Next (→ or Space)">
                Next →
            </button>
            <button class="control-btn" id="toggleNotes" title="Toggle Presenter Notes (N)">
                📝 Notes
            </button>
            <button class="control-btn" id="exitPresentation" title="Exit (Esc)">
                ✕ Exit
            </button>
        `;

        // Create presenter notes panel
        const notesPanel = document.createElement('div');
        notesPanel.className = 'presenter-notes';
        notesPanel.id = 'presenterNotes';
        notesPanel.style.display = 'none';
        notesPanel.innerHTML = `
            <h4>📝 Presenter Notes</h4>
            <div class="notes-content" id="notesContent">
                <p><em>No notes for this slide</em></p>
            </div>
        `;

        // Create slide content container
        const slideContent = document.createElement('div');
        slideContent.className = 'slide-content';
        slideContent.id = 'slideContent';

        // Assemble presentation container
        presContainer.appendChild(progressBar);
        presContainer.appendChild(slideContent);
        presContainer.appendChild(controls);
        presContainer.appendChild(notesPanel);

        document.body.appendChild(presContainer);

        // Add event listeners for controls
        document.getElementById('prevSlide').addEventListener('click', () => this.prevSlide());
        document.getElementById('nextSlide').addEventListener('click', () => this.nextSlide());
        document.getElementById('exitPresentation').addEventListener('click', () => this.exitPresentation());
        document.getElementById('toggleNotes').addEventListener('click', () => this.togglePresenterNotes());
    }

    setupKeyboardControls() {
        document.addEventListener('keydown', (e) => {
            if (!this.isPresenting) return;

            // Prevent default behavior for presentation keys
            const presentationKeys = ['ArrowRight', 'ArrowLeft', ' ', 'Escape', 'f', 'F11', 'n', 'N'];
            if (presentationKeys.includes(e.key)) {
                e.preventDefault();
            }

            switch(e.key) {
                case 'ArrowRight':
                case ' ': // Spacebar
                    this.nextSlide();
                    break;
                case 'ArrowLeft':
                case 'Backspace':
                    this.prevSlide();
                    break;
                case 'Escape':
                    this.exitPresentation();
                    break;
                case 'f':
                case 'F11':
                    this.toggleFullscreen();
                    break;
                case 'n':
                case 'N':
                    this.togglePresenterNotes();
                    break;
                case 'Home':
                    this.goToSlide(0);
                    break;
                case 'End':
                    this.goToSlide(this.slides.length - 1);
                    break;
                default:
                    // Number keys 1-9 for quick jump
                    const num = parseInt(e.key);
                    if (num >= 1 && num <= 9 && num <= this.slides.length) {
                        this.goToSlide(num - 1);
                    }
                    break;
            }
        });
    }

    setupMouseControls() {
        // Track mouse movement for auto-hiding controls
        document.addEventListener('mousemove', () => {
            if (!this.isPresenting) return;

            this.lastMouseMove = Date.now();

            if (this.controlsHidden) {
                this.showControls();
            }

            // Reset auto-hide timer
            clearTimeout(this.autoHideTimer);
            this.autoHideTimer = setTimeout(() => {
                if (this.isPresenting && !this.presenterNotesVisible) {
                    this.hideControls();
                }
            }, this.config.autoHideControls);
        });
    }

    startPresentation() {
        console.log('🎬 Starting presentation...');

        this.isPresenting = true;
        this.currentSlide = 0;

        // Hide normal page content
        document.body.style.overflow = 'hidden';

        // Show presentation container
        const presContainer = document.getElementById('presentation-container');
        presContainer.style.display = 'flex';

        // Render first slide
        this.renderSlide();

        // Request fullscreen (optional, user can press F11)
        // this.toggleFullscreen();

        console.log('✅ Presentation started');
    }

    exitPresentation() {
        console.log('🛑 Exiting presentation...');

        this.isPresenting = false;

        // Restore normal page
        document.body.style.overflow = 'auto';

        // Hide presentation container
        const presContainer = document.getElementById('presentation-container');
        presContainer.style.display = 'none';

        // Exit fullscreen if active
        if (document.fullscreenElement) {
            document.exitFullscreen();
        }

        console.log('✅ Presentation exited');
    }

    nextSlide() {
        if (this.currentSlide < this.slides.length - 1) {
            this.currentSlide++;
            this.renderSlide();
        } else {
            console.log('📍 Already at last slide');
        }
    }

    prevSlide() {
        if (this.currentSlide > 0) {
            this.currentSlide--;
            this.renderSlide();
        } else {
            console.log('📍 Already at first slide');
        }
    }

    goToSlide(index) {
        if (index >= 0 && index < this.slides.length) {
            this.currentSlide = index;
            this.renderSlide();
        }
    }

    renderSlide() {
        const slide = this.slides[this.currentSlide];
        const slideContent = document.getElementById('slideContent');

        // Clone slide element to avoid modifying original
        const slideClone = slide.element.cloneNode(true);

        // Clear previous slide content
        slideContent.innerHTML = '';
        slideContent.appendChild(slideClone);

        // Add fade-in animation
        slideContent.style.opacity = '0';
        setTimeout(() => {
            slideContent.style.opacity = '1';
        }, 50);

        // Update progress indicator
        this.updateProgress();

        // Update presenter notes
        this.updatePresenterNotes();

        console.log(`📄 Rendered slide ${this.currentSlide + 1}: ${slide.title}`);
    }

    updateProgress() {
        const progressFill = document.getElementById('progressFill');
        const progressText = document.getElementById('progressText');
        const slideNumber = document.getElementById('slideNumber');

        const percentage = ((this.currentSlide + 1) / this.slides.length) * 100;

        progressFill.style.width = `${percentage}%`;
        progressText.textContent = `Slide ${this.currentSlide + 1} of ${this.slides.length}`;
        slideNumber.textContent = `${this.currentSlide + 1} / ${this.slides.length}`;
    }

    updatePresenterNotes() {
        const notesContent = document.getElementById('notesContent');
        const slide = this.slides[this.currentSlide];

        if (slide.notes && slide.notes.trim() !== '') {
            notesContent.innerHTML = `<p>${slide.notes}</p>`;
        } else {
            notesContent.innerHTML = `<p><em>No notes for this slide</em></p>`;
        }
    }

    togglePresenterNotes() {
        this.presenterNotesVisible = !this.presenterNotesVisible;
        const notesPanel = document.getElementById('presenterNotes');
        notesPanel.style.display = this.presenterNotesVisible ? 'block' : 'none';

        console.log(`📝 Presenter notes: ${this.presenterNotesVisible ? 'visible' : 'hidden'}`);
    }

    showControls() {
        const controls = document.querySelector('.presentation-controls');
        const progressBar = document.querySelector('.presentation-progress');

        controls.style.opacity = '1';
        controls.style.transform = 'translateY(0)';
        progressBar.style.opacity = '1';

        this.controlsHidden = false;
    }

    hideControls() {
        const controls = document.querySelector('.presentation-controls');
        const progressBar = document.querySelector('.presentation-progress');

        controls.style.opacity = '0';
        controls.style.transform = 'translateY(20px)';
        progressBar.style.opacity = '0';

        this.controlsHidden = true;
    }

    toggleFullscreen() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen().catch(err => {
                console.error(`Error attempting to enable fullscreen: ${err.message}`);
            });
            console.log('🖥️ Fullscreen enabled');
        } else {
            document.exitFullscreen();
            console.log('🖥️ Fullscreen disabled');
        }
    }
}

// Initialize presentation mode when DOM is ready
let presentationMode;

document.addEventListener('DOMContentLoaded', () => {
    presentationMode = new PresentationMode();

    // Add start presentation button (if not already present)
    const existingButton = document.getElementById('startPresentationBtn');
    if (!existingButton) {
        const header = document.querySelector('header');
        if (header) {
            const startButton = document.createElement('button');
            startButton.id = 'startPresentationBtn';
            startButton.className = 'btn btn-primary';
            startButton.innerHTML = '🎬 Start Presentation';
            startButton.style.marginTop = '20px';
            startButton.addEventListener('click', () => presentationMode.startPresentation());
            header.appendChild(startButton);
        }
    }
});

// Export for external use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PresentationMode;
}
