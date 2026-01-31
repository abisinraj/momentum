
(function () {
    const muscles = [
        'Neck', 'Traps', 'Chest', 'Upper Back', 'Lats', 'Lower Back',
        'Front Shoulders', 'Side Shoulders', 'Rear Shoulders',
        'Biceps', 'Triceps', 'Forearms',
        'Upper Abs', 'Lower Abs', 'Obliques',
        'Glutes', 'Quads', 'Hamstrings', 'Inner Thighs', 'Outer Thighs', 'Calves', 'Shins'
    ];

    let index = 0;

    function next() {
        if (index >= muscles.length) {
            console.log("Showcase complete!");
            window.resetHeatmap();
            return;
        }

        const muscle = muscles[index];
        console.log(`Showing: ${muscle} (${index + 1}/${muscles.length})`);

        window.resetHeatmap();
        window.setMuscleHeatmap({ [muscle]: 1.0 });

        index++;
        setTimeout(next, 5000);
    }

    console.log("Starting muscle showcase (5s per muscle)...");

    // Wait for model to load if not ready
    if (typeof window.setMuscleHeatmap !== 'function' || !window.model) {
        console.log("Waiting for viewer to be ready...");
        const checkReady = setInterval(() => {
            if (typeof window.setMuscleHeatmap === 'function' && window.model) {
                clearInterval(checkReady);
                next();
            }
        }, 100);
    } else {
        next();
    }
})();
