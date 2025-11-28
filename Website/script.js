// Three.js 3D Background
function initThreeBackground() {
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ alpha: true });
    
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.getElementById('three-bg').appendChild(renderer.domElement);
    
    // Create floating geometric shapes
    const geometries = [
        new THREE.BoxGeometry(1, 1, 1),
        new THREE.SphereGeometry(0.7, 32, 32),
        new THREE.ConeGeometry(0.8, 1.5, 32),
        new THREE.TorusGeometry(1, 0.3, 16, 100)
    ];
    
    const materials = [
        new THREE.MeshBasicMaterial({ color: 0x007A3D, wireframe: true }),
        new THREE.MeshBasicMaterial({ color: 0xC2A83E, wireframe: true }),
        new THREE.MeshBasicMaterial({ color: 0x4CAF50, wireframe: true })
    ];
    
    const objects = [];
    
    // Create multiple floating objects
    for (let i = 0; i < 15; i++) {
        const geometry = geometries[Math.floor(Math.random() * geometries.length)];
        const material = materials[Math.floor(Math.random() * materials.length)];
        const mesh = new THREE.Mesh(geometry, material);
        
        mesh.position.x = Math.random() * 40 - 20;
        mesh.position.y = Math.random() * 40 - 20;
        mesh.position.z = Math.random() * 40 - 20;
        
        mesh.rotation.x = Math.random() * Math.PI;
        mesh.rotation.y = Math.random() * Math.PI;
        
        mesh.userData = {
            speedX: (Math.random() - 0.5) * 0.02,
            speedY: (Math.random() - 0.5) * 0.02,
            speedZ: (Math.random() - 0.5) * 0.02,
            rotationSpeedX: (Math.random() - 0.5) * 0.02,
            rotationSpeedY: (Math.random() - 0.5) * 0.02
        };
        
        scene.add(mesh);
        objects.push(mesh);
    }
    
    camera.position.z = 30;
    
    // Animation
    function animate() {
        requestAnimationFrame(animate);
        
        objects.forEach(obj => {
            obj.position.x += obj.userData.speedX;
            obj.position.y += obj.userData.speedY;
            obj.position.z += obj.userData.speedZ;
            
            obj.rotation.x += obj.userData.rotationSpeedX;
            obj.rotation.y += obj.userData.rotationSpeedY;
            
            // Bounce off boundaries
            if (Math.abs(obj.position.x) > 20) obj.userData.speedX *= -1;
            if (Math.abs(obj.position.y) > 20) obj.userData.speedY *= -1;
            if (Math.abs(obj.position.z) > 20) obj.userData.speedZ *= -1;
        });
        
        renderer.render(scene, camera);
    }
    
    animate();
    
    // Handle window resize
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
}

// Initialize Three.js background
initThreeBackground();

// Create animated logo background
function createLogoBackground() {
    const logoBackground = document.getElementById('logo-background');
    const logoCount = 15;
    
    for (let i = 0; i < logoCount; i++) {
        const logo = document.createElement('div');
        logo.classList.add('floating-logo');
        
        // Create SVG logo
        logo.innerHTML = `
            <svg viewBox="0 0 851 315" xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <style>
                        .cls-1 { fill: #c9e4c0; }
                        .cls-2 { fill: #134f49; }
                        .cls-3 { fill: #eea85b; }
                    </style>
                </defs>
                <path class="cls-2" d="M588.1,6.09h-325.2c-.75,0-1.37.61-1.37,1.37v300.09c0,.75.61,1.37,1.37,1.37h325.2c.75,0,1.37-.61,1.37-1.37V7.45c0-.75-.61-1.37-1.37-1.37ZM397.39,234.95c-24.24-7.03-32.76-33.68-47.01-51.9-1.96-1.73-8.23.89-10.33,2.16-17.56,10.64-.77,35.82-14.02,48.65-2.48,2.4-9.05,6.02-12.48,6.02h-23.41l-.59-1.3c.03-.78.06-1.57.09-2.35-.02.02-.04.05-.06.07l-.16-31.49c-.17-7.47-.3-14.93-.12-22.29l-.56-108.69s0,0,0,0c0-2.88.06-5.7.07-8.35l81.37-.02c35.4,2.2,64.89,34.5,54.42,70.69-4.7,16.26-17.52,28.64-32.35,35.99l42.65,64.72c-12.35-.61-25.56,1.57-37.54-1.91ZM538.24,236.94c-37.1-.32-78.1,3.76-90.83-6.18-15.39-16.67-8.14-39.44,14.64-66.39.77-7.21,7.6-21.26,13.4-25.22,13.75-9.38,41.84-9.81,65.77,3.09-9.54,13.11-19.06,23.66-28.54,29.08-12.69,7.36-26.11,7.84-40.45-.26v27.28c.97,3.97,3.08,5.04,5.46,5.66h77.49c.24,17.18-3.49,30.18-16.94,32.94ZM553.84,103.91l-75.55.51v30.36c-16.6,6.13-28.91,25.69-38.68,53.18l-.36-117.34h129.21c1.07,19.03-2.72,31.58-14.63,33.28Z"/>
                <path class="cls-1" d="M477.69,204.01c-2.38-.62-4.49-1.69-5.46-5.66v-27.28c14.34,8.1,27.77,7.61,40.45.26,9.48-5.42,19-15.97,28.54-29.08-23.93-12.9-52.02-12.47-65.77-3.09-5.8,3.96-12.63,18-13.4,25.22-22.78,26.95-30.03,49.72-14.64,66.39,12.73,9.93,53.74,5.85,90.83,6.18,13.45-2.76,17.17-15.76,16.94-32.94h-77.49Z"/>
            </svg>
        `;
        
        // Random position
        logo.style.left = `${Math.random() * 100}%`;
        logo.style.top = `${Math.random() * 100}%`;
        
        // Random animation delay and duration
        const delay = Math.random() * 20;
        const duration = Math.random() * 10 + 20;
        logo.style.animationDelay = `${delay}s`;
        logo.style.animationDuration = `${duration}s`;
        
        // Random size
        const size = Math.random() * 60 + 60;
        logo.style.width = `${size}px`;
        
        logoBackground.appendChild(logo);
    }
}

// Points system
let userPoints = 0;
const pointsElement = document.getElementById('points');

function addPoints(amount) {
    userPoints += amount;
    pointsElement.textContent = userPoints;
    
    // Add animation to points counter
    pointsElement.style.transform = 'scale(1.5)';
    setTimeout(() => {
        pointsElement.style.transform = 'scale(1)';
    }, 300);
    
    // Check for badge unlocks
    checkBadgeUnlocks();
}

function checkBadgeUnlocks() {
    const badges = document.querySelectorAll('.badge.locked');
    badges.forEach(badge => {
        if (userPoints >= 100) {
            badge.classList.remove('locked');
            badge.style.background = 'var(--accent)';
        }
    });
}

// Recycling game
const recyclingBin = document.getElementById('recycling-bin');
const gameFeedback = document.getElementById('game-feedback');
const gameProgress = document.getElementById('game-progress');
let gameScore = 0;

// Make game items draggable
document.querySelectorAll('.game-item').forEach(item => {
    item.addEventListener('dragstart', (e) => {
        e.dataTransfer.setData('text/plain', e.target.dataset.type);
    });
});

// Allow drop on recycling bin
recyclingBin.addEventListener('dragover', (e) => {
    e.preventDefault();
    recyclingBin.style.transform = 'scale(1.1)';
});

recyclingBin.addEventListener('dragleave', () => {
    recyclingBin.style.transform = 'scale(1)';
});

recyclingBin.addEventListener('drop', (e) => {
    e.preventDefault();
    recyclingBin.style.transform = 'scale(1)';
    
    const itemType = e.dataTransfer.getData('text/plain');
    const pointsEarned = 10;
    
    // Add points
    addPoints(pointsEarned);
    gameScore += pointsEarned;
    
    // Update progress
    const progressPercent = Math.min((gameScore / 100) * 100, 100);
    gameProgress.style.width = `${progressPercent}%`;
    
    // Show feedback
    gameFeedback.textContent = `+${pointsEarned} points! Good job recycling ${itemType}!`;
    gameFeedback.style.color = 'var(--primary)';
    
    // Reset feedback after delay
    setTimeout(() => {
        gameFeedback.textContent = '';
    }, 2000);
    
    // Check for game completion
    if (gameScore >= 100) {
        gameFeedback.textContent = 'Congratulations! You\'ve completed the recycling challenge!';
        gameFeedback.style.color = 'var(--accent)';
    }
});

// Scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            
            // Stagger animations for list items
            if (entry.target.querySelector('.features-list')) {
                const listItems = entry.target.querySelectorAll('.features-list li');
                listItems.forEach((item, index) => {
                    item.style.transitionDelay = `${index * 0.1}s`;
                });
            }
            
            // Stagger animations for steps
            if (entry.target.querySelector('.steps')) {
                const steps = entry.target.querySelectorAll('.step');
                steps.forEach((step, index) => {
                    step.style.transitionDelay = `${index * 0.1}s`;
                });
            }
            
            // Stagger animations for partners
            if (entry.target.querySelector('.partners-grid')) {
                const partners = entry.target.querySelectorAll('.partner');
                partners.forEach((partner, index) => {
                    partner.style.transitionDelay = `${index * 0.1}s`;
                });
            }
            
            // Stagger animations for FAQ
            if (entry.target.querySelector('details')) {
                const details = entry.target.querySelectorAll('details');
                details.forEach((detail, index) => {
                    detail.style.transitionDelay = `${index * 0.1}s`;
                });
            }
        }
    });
}, observerOptions);

// Observe all sections
document.querySelectorAll('.section').forEach(section => {
    observer.observe(section);
});

// Header scroll effect
window.addEventListener('scroll', () => {
    const header = document.querySelector('.site-header');
    if (window.scrollY > 50) {
        header.classList.add('scrolled');
    } else {
        header.classList.remove('scrolled');
    }
});

// Mobile menu toggle
const menuToggle = document.querySelector('.menu-toggle');
const mainNav = document.querySelector('.main-nav');

if (menuToggle) {
    menuToggle.addEventListener('click', () => {
        mainNav.classList.toggle('active');
    });
}

// Simple notify handler
document.getElementById('notify-btn')?.addEventListener('click', () => {
    const email = document.getElementById('notify-email')?.value.trim();
    if (!email) { 
        alert('Please enter a valid email.'); 
        return; 
    }
    if (!validateEmail(email)) {
        alert('Please enter a valid email address.');
        return;
    }
    alert('Thanks — we will notify ' + email + ' when ReWard launches in your area.');
    document.getElementById('notify-email').value = '';
});

// Fake download buttons
document.getElementById('download-android')?.addEventListener('click', () => {
    alert('Replace this with your Google Play store link.');
});
document.getElementById('download-ios')?.addEventListener('click', () => {
    alert('Replace this with your App Store link.');
});

// Email validation
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', function(e){
        const id = this.getAttribute('href');
        if (id.length > 1) {
            e.preventDefault();
            const el = document.querySelector(id);
            if (el) el.scrollIntoView({behavior:'smooth', block:'start'});
        }
    });
});

// Initialize logo background
createLogoBackground();