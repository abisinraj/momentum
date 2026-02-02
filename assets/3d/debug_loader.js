
// Debug Auto-loader (only for local testing)
if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') {
    console.log('🛠️ Debug Loader: Waiting for dependencies...');

    // Wait for all dependencies to load
    setTimeout(() => {
        if (window.GLTFLoader && window.onModelLoaded) {
            console.log('🛠️ Debug Loader: Loading model.glb...');
            const loader = new window.GLTFLoader();
            loader.load('model.glb', (gltf) => {
                console.log("🛠️ Debug Loader: Model loaded successfully!");
                window.onModelLoaded(gltf);
            }, (progress) => {
                const percent = (progress.loaded / progress.total * 100).toFixed(0);
                console.log(`🛠️ Loading: ${percent}%`);
            }, (err) => {
                console.error("🛠️ Debug Loader: Failed to load model.glb", err);
            });
        } else {
            console.error('🛠️ Debug Loader: GLTFLoader or onModelLoaded not found!');
        }
    }, 500);
}
