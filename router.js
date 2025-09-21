// Simple client-side router for GitHub Pages
// Handles username-based routing like beniah.games/leyno

(function() {
    // Only run on the main page
    if (window.location.pathname !== '/' && !window.location.pathname.endsWith('/index.html')) {
        return;
    }
    
    // Check if there's a hash that could be a username
    if (window.location.hash && window.location.hash.length > 1) {
        const potentialUsername = window.location.hash.substring(1);
        
        // Skip if it's a known hash (like #signup)
        const knownHashes = ['signup', 'login', 'about', 'games', 'devlogs'];
        if (!knownHashes.includes(potentialUsername.toLowerCase())) {
            // Redirect to user profile
            window.location.href = `/user/?u=${potentialUsername}`;
            return;
        }
    }
    
    // Check URL parameters for username
    const urlParams = new URLSearchParams(window.location.search);
    const username = urlParams.get('u') || urlParams.get('user');
    if (username) {
        // Redirect to user profile
        window.location.href = `/user/?u=${username}`;
        return;
    }
})();