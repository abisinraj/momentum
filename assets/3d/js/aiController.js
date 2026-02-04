window.aiController = {
    enabled: false,
    difficulty: 'medium',
    lastAttackTime: 0,
    attackCooldown: 3000,
    isAttacking: false,
    isStunned: false,
    stunEndTime: 0,
    attackDuration: 500, // Faster, snappier punches

    // Movement State
    targetX: 0,
    targetZ: -1.0, // Base distance
    moveTimer: 0,
    lungeState: null, // New object for smooth animation { startTime, duration, startZ, depth, damage }

    patterns: {
        easy: { cooldown: 4000, damage: 3, comboChance: 0.1, moveSpeed: 0.02 },
        medium: { cooldown: 2500, damage: 5, comboChance: 0.6, moveSpeed: 0.04 },
        hard: { cooldown: 1500, damage: 8, comboChance: 1.0, moveSpeed: 0.06 }
    },

    init: function () {
        window.aiController = this; // Explicitly expose to window for handleGameHit
        console.log("🤖 AI Controller Initialized (v5.1 - VISIBILITY FIXED)");
        this.enabled = false;
        this.lastAttackTime = 0;
        this.isAttacking = false;
        this.isGuarding = false;
        this.isStunned = false;
        this.stunEndTime = 0;
        this.comboQueue = []; // Init Queue
        this.playerHitLog = []; // Anti-Spam Log
        if (typeof model !== 'undefined' && model) {
            model.position.x = 0;
            model.position.z = 0;
        }
        console.log('🤖 AI Controller Initialized (v4.0 - Combo Master)');
    },

    update: function (time) {
        if (!this.enabled || (typeof window.gameMode !== 'undefined' && !window.gameMode) || (typeof window.model === 'undefined' || !window.model)) return;

        // Prune Hit Log
        const now = Date.now();
        if (this.playerHitLog && this.playerHitLog.length > 0) {
            this.playerHitLog = this.playerHitLog.filter(t => now - t < 2000);
        }

        // SAFETY: Prevent Vanishing & Drift
        if (isNaN(window.model.position.x) || isNaN(window.model.position.z)) {
            window.model.position.set(0, 0, 0);
        }

        // 0. HIT STUN CHECK
        if (this.isStunned) {
            if (time < this.stunEndTime) {
                return; // Cannot move or attack while stunned
            } else {
                this.isStunned = false;
            }
        }

        // === DYNAMIC DIFFICULTY ===
        // Adjust based on health differential
        const playerHP = (typeof window.playerHealth !== 'undefined') ? window.playerHealth : 100;
        const aiHP = (typeof window.modelHealth !== 'undefined') ? window.modelHealth : 100;
        const healthDiff = aiHP - playerHP; // Positive = AI winning, Negative = Player winning

        // Base pattern
        let pattern = { ...this.patterns[this.difficulty] };

        if (healthDiff < -20) {
            // Player dominating - AI gets faster and more aggressive
            pattern.cooldown = Math.max(800, pattern.cooldown * 0.7);
            pattern.comboChance = Math.min(1.0, pattern.comboChance + 0.2);
            console.log("🔥 AI ADAPTING: Getting aggressive!");
        } else if (healthDiff > 20) {
            // AI dominating - relax slightly
            pattern.cooldown = pattern.cooldown * 1.2;
            pattern.comboChance = Math.max(0.3, pattern.comboChance - 0.1);
        }

        // 1. Organic Movement (Layered Sine Waves for "Life" - Increased for Footwork)
        if (!this.isAttacking) {
            const t = time * 0.001;
            const w1 = Math.sin(t * pattern.moveSpeed * 20);
            const w2 = Math.sin(t * 0.5);
            const offsetX = (w1 * 0.3) + (w2 * 0.15); // Restored full magnitude for Footwork

            const w3 = Math.cos(t * pattern.moveSpeed * 15);
            const offsetZ = (w3 * 0.15) - (Math.sin(t * 0.2) * 0.1); // Restored footwork logic

            const bobY = (Math.sin(t * 2.5) * 0.015);
            const smooth = 0.03;
            window.model.position.x += (offsetX - window.model.position.x) * smooth;
            window.model.position.z += (offsetZ - window.model.position.z) * smooth;
            window.model.position.y += (bobY - window.model.position.y) * 0.1;
        }

        // 2. Lunge & Attack Animation Loop (Frame Perfect)
        if (this.lungeState) {
            const now = Date.now();
            const state = this.lungeState;
            const elapsed = now - state.startTime;
            const progress = Math.min(elapsed / state.duration, 1.0);

            // Forward then Back (Sine wave for lunge)
            const offset = Math.sin(progress * Math.PI) * state.depth;
            model.position.z = (state.startZ || 0) + offset;

            // KINETIC CHAIN LOGIC
            // Note: Pose updates for Type 1-6 are handled entirely by setTimeout in executeSingleStrike
            if (state.type >= 1 && state.type <= 6) {
                // Do nothing here for pose. Let Timeouts drive it.
                // Apply Vertical physics for uppercuts if needed
                if (state.verticalDrive) {
                    // Sync with Impact Time (approx 150ms)
                    const riseTime = 150;
                    if (elapsed < riseTime) {
                        // RISING (0 -> 150ms)
                        const riseProgress = elapsed / riseTime;
                        model.position.y = (state.startY || 0) + (riseProgress * 0.2);
                    } else if (elapsed < riseTime * 2) {
                        // SETTLING (150ms -> 300ms)
                        const settleProgress = (elapsed - riseTime) / riseTime;
                        model.position.y = (state.startY || 0) + (0.2 - (settleProgress * 0.2));
                    } else {
                        model.position.y = 0;
                    }
                }
            }

            // HIT TRIGGER (At peak of lunge ~50%)
            if (progress >= 0.5 && !state.hitTriggered) {
                state.hitTriggered = true;
                this.hitPlayer(state.damage, state.isCombo);
                this.shakeCamera(state.depth > 1.5 ? 0.25 : 0.15);
            }

            if (progress >= 1.0) {
                // End of attack
                if (model) model.position.z = (state.startZ || 0); // Ensure reset
                this.lungeState = null;
                this.isAttacking = false;
                if (window.stanceController) window.stanceController.targetPose = 'FIGHT';
            }
        }

        // 3. Attack Logic (Combos)
        const timeSinceLastAttack = time - this.lastAttackTime;
        if (timeSinceLastAttack > pattern.cooldown && !this.isAttacking && !this.lungeState && (!this.comboQueue || this.comboQueue.length === 0)) {
            this.decideAttack(pattern);
            this.lastAttackTime = time;
        }
    },

    executeAttack: function (damage) {
        if (this.isAttacking || this.lungeState || this.isStunned) return;
        this.isAttacking = true;

        // Pick from 1-6 Basic Strikes
        const type = Math.floor(Math.random() * 6) + 1;
        const attackPose = `ATTACK_${type}`;

        if (window.stanceController) window.stanceController.targetPose = attackPose;

        // Initialize Lunge State for Update Loop
        this.lungeState = {
            startTime: Date.now(),
            duration: 400,
            startZ: (model && model.position) ? (model.position.z || 0) : 0,
            depth: 1.6,
            damage: damage,
            hitTriggered: false,
            isCombo: false
        };
    },


    decideAttack: function (pattern) {
        const isCombo = Math.random() < pattern.comboChance;

        if (isCombo) {
            // ADVANCED COMBO DEFINITIONS (Type + Zone)
            const combos = [
                // 1. The Classic (1-2 Head)
                [{ type: 1, zone: 'HEAD' }, { type: 2, zone: 'HEAD' }],
                // 2. Double Jab Cross
                [{ type: 1, zone: 'HEAD' }, { type: 1, zone: 'HEAD' }, { type: 2, zone: 'HEAD' }],
                // 3. The Finisher (1-2-3 Hard)
                [{ type: 1, zone: 'HEAD' }, { type: 2, zone: 'HEAD' }, { type: 3, zone: 'HEAD' }],
                // 4. Body Snatcher (Jab Head -> Cross Body -> Left Hook Head)
                [{ type: 1, zone: 'HEAD' }, { type: 2, zone: 'BODY' }, { type: 3, zone: 'HEAD' }],
                // 5. Inside Fighting (Body Hook -> Head Hook)
                [{ type: 3, zone: 'BODY' }, { type: 4, zone: 'HEAD' }],
                // 6. Right Hand Lead (Surprise)
                [{ type: 2, zone: 'HEAD' }, { type: 3, zone: 'HEAD' }],
                // 7. The Uplift (Jab -> Rear Uppercut)
                [{ type: 1, zone: 'HEAD' }, { type: 6, zone: 'HEAD' }],
                // 8. Inside Demolition (Left Uppercut Body -> Right Hook Head)
                [{ type: 5, zone: 'BODY' }, { type: 4, zone: 'HEAD' }],
                // 9. Shoeshine (Uppercuts Flurry -> Hook)
                [{ type: 5, zone: 'BODY' }, { type: 6, zone: 'BODY' }, { type: 3, zone: 'HEAD' }]
            ];
            this.comboQueue = combos[Math.floor(Math.random() * combos.length)];
            console.log(`🤖 Combo Queue:`, this.comboQueue);
        } else {
            // Single pot-shot
            const type = Math.floor(Math.random() * 6) + 1;
            this.comboQueue = [{ type: type, zone: 'HEAD' }];
            if (Math.random() < 0.3) this.comboQueue[0].zone = 'BODY';
        }

        this.processComboStep(pattern.damage);
    },

    processComboStep: function (damage) {
        if (!this.comboQueue || this.comboQueue.length === 0) {
            this.isAttacking = false;
            return;
        }

        this.isAttacking = true;
        this.isAttacking = true;
        const step = this.comboQueue.shift();

        let type, zone;
        if (typeof step === 'object') {
            type = step.type;
            zone = step.zone;
        } else {
            type = step; // Legacy fallback
            zone = 'HEAD';
        }

        this.executeSingleStrike(type, damage, zone);

        // DYNAMIC FLOW DELAY
        let delay = 350; // Default fast follow-up
        if (type === 1) delay = 250; // Jabs are super fast
        else if (type === 2) delay = 400; // Cross needs recover
        else delay = 500; // Hooks/Uppercuts need reload

        // Increase delay if switching hands awkwardness? 
        // Actually, opposite hands flow faster. Same hand = slower.
        // We'll keep it simple for now.

        setTimeout(() => {
            if (this.enabled && (typeof gameMode !== 'undefined' ? gameMode : window.gameMode)) this.processComboStep(damage);
        }, delay);
    },

    executeSingleStrike: function (type, damage, zone = 'HEAD') {
        if (this.lungeState || this.isStunned) return; // CRITICAL GUARD
        if (!window.stanceController) return;

        // --- KINETIC CHAIN FOR JAB (Type 1) ---
        if (type === 1) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_1']));
            // Incorporate dynamic aiming
            if (zone.includes('BODY')) {
                fullPose['Spine'].rx += 0.45; // Down
            } else if (zone.includes('LEFT')) {
                fullPose['Spine'].ry -= 0.2; // Aim Left
            } else if (zone.includes('RIGHT')) {
                fullPose['Spine'].ry += 0.2; // Aim Right
            }

            // Phase 1: GROUND FORCE (Leaves feet, Hips start)
            // We start with the FIGHT pose but inject the lower body triggers
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['FIGHT']));
            p1['RightUpLeg'] = fullPose['RightUpLeg'];
            p1['LeftUpLeg'] = fullPose['LeftUpLeg'];
            p1['Hips'] = fullPose['Hips']; // Hip Turn
            p1['Spine'] = window.stanceController.poses['ATTACK_1_START']['Spine']; // Lagging Spine

            window.stanceController.targetPose = p1;

            // Phase 2: KINETIC TRANSFER (Shoulder Drive + Uncoil) ~40ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Spine'] = fullPose['Spine']; // Snap Torso
                p2['LeftArm'] = fullPose['LeftArm']; // Drive Shoulder
                // START EXTENSION: Partial uncoil
                p2['LeftForeArm'] = { rx: 0, ry: 0, rz: 0.8 };
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 40);

            // Phase 3: MAX EXTENSION (Snap) ~80ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                // OVERDRIVE: Target slightly past 0 (-0.2)
                p3['LeftForeArm'] = { rx: 0, ry: 0, rz: -0.2 };
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 80);

            // Phase 4: IMPACT HOLD (Lockout) ~120ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                if (window.stanceController) window.stanceController.targetPose = fullPose; // Settle at 0.0
            }, 120);

            this.lungeState = {
                startTime: Date.now(),
                duration: 350, // Fast Snap
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                // REDUCED DEPTH: 1.6 for Head (prevents camera clip), 1.4 for Body
                depth: zone.includes('BODY') ? 1.4 : 1.6,
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                dynamicPose: fullPose
            };
            return;
        }

        // --- KINETIC CHAIN FOR CROSS (Type 2) ---
        if (type === 2) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_2']));

            // VARIATIONS
            if (zone.includes('BODY')) {
                fullPose['Spine'].rx += 0.45; // Lean Down
                fullPose['RightArm'].rx += 0.2; // Angle Down
                // Deep Knee Bend for Power
                fullPose['RightUpLeg'].rx -= 0.3;
                fullPose['LeftUpLeg'].rx -= 0.2;
            } else if (zone.includes('LEFT')) {
                fullPose['Spine'].ry -= 0.25;
            } else if (zone.includes('RIGHT')) {
                fullPose['Spine'].ry += 0.25;
            }

            // Phase 1: REAR FOOT DRIVE (Windup/Load)
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_2_START']));
            window.stanceController.targetPose = p1;

            // Phase 2: TORQUE (Hips & Spine Snap) ~50ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Hips'] = fullPose['Hips']; // Fire Hips
                p2['Spine'] = fullPose['Spine']; // Fire Spine
                p2['RightArm'] = fullPose['RightArm']; // Shoulder Drive
                p2['RightForeArm'] = { rx: 0, ry: 0, rz: 0.8 }; // Uncoil
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 50);

            // Phase 3: EXTENSION (Snap) ~80ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                // OVERDRIVE
                p3['RightForeArm'] = { rx: 0, ry: 0, rz: -0.2 };
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 80);

            // Phase 4: IMPACT (Lockout) ~120ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                if (window.stanceController) window.stanceController.targetPose = fullPose;
            }, 120);

            this.lungeState = {
                startTime: Date.now(),
                duration: 450, // Power Commit
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                depth: zone.includes('BODY') ? 1.4 : 1.6,
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                dynamicPose: fullPose
            };
            return;
        }

        // --- KINETIC CHAIN FOR LEFT HOOK (Type 3) ---
        if (type === 3) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_3']));

            // VARIATIONS
            if (zone.includes('BODY')) { // LIVER SHOT
                // Mechanics change: Shovel Hook (45 deg up)
                fullPose['Spine'].rx += 0.3; // Lean Down
                fullPose['Spine'].ry += 0.2; // Lean into it
                // Drop levels
                fullPose['RightUpLeg'].rx -= 0.4;
                fullPose['LeftUpLeg'].rx -= 0.4;
                // Arm Angle: Lower elbow, punch up
                fullPose['LeftArm'].rz -= 0.5; // Elbow down
                fullPose['LeftArm'].rx -= 0.2; // Punch up
            } else {
                // Aiming adjustments
                if (zone.includes('LEFT')) fullPose['Spine'].ry -= 0.2;
                if (zone.includes('RIGHT')) fullPose['Spine'].ry += 0.2;
            }

            // Phase 1: THE LOAD (Cock back ~0ms)
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_3_START']));
            window.stanceController.targetPose = p1;

            // Phase 2: THE PIVOT (Hips & Feet First) ~100ms (Slower telegraph)
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Hips'] = fullPose['Hips']; // Fire hips Right
                p2['LeftUpLeg'] = fullPose['LeftUpLeg']; // Pivot Lead Leg
                p2['Spine'] = fullPose['Spine']; // Start Spine turn
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 100);

            // Phase 3: THE WHIP (Arm Snap) ~240ms (Delayed Impact)
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                // OVERDRIVE: Whip slightly past center for snap
                p3['Spine'].ry += 0.2;
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 240);

            // Phase 4: SETTLE ~350ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                window.stanceController.targetPose = fullPose;
            }, 350);

            this.lungeState = {
                startTime: Date.now(),
                duration: 700, // Slower for Counter Opportunity
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                depth: zone.includes('BODY') ? 1.4 : 1.4, // Hooks are short range
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                dynamicPose: fullPose
            };
            return;
        }

        // --- KINETIC CHAIN FOR RIGHT HOOK (Type 4) ---
        if (type === 4) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_4']));

            // VARIATIONS
            if (zone.includes('BODY')) { // SPLEEN SHOT
                // Mechanics change: Shovel Hook (45 deg up)
                fullPose['Spine'].rx += 0.3; // Lean Down
                fullPose['Spine'].ry -= 0.2; // Lean into it
                // Drop levels
                fullPose['RightUpLeg'].rx -= 0.4;
                fullPose['LeftUpLeg'].rx -= 0.4;
                // Arm Angle: Lower elbow, punch up
                fullPose['RightArm'].rz += 0.5; // Elbow down (Inverse for Right Arm rz-ish)
                fullPose['RightArm'].rx -= 0.2; // Punch up
            } else {
                // Aiming adjustments
                if (zone.includes('LEFT')) fullPose['Spine'].ry -= 0.2;
                if (zone.includes('RIGHT')) fullPose['Spine'].ry += 0.2;
            }

            // Phase 1: THE LOAD (Cock back ~0ms)
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_4_START']));
            window.stanceController.targetPose = p1;

            // Phase 2: THE PIVOT (Hips & Feet First) ~100ms (Slower telegraph)
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Hips'] = fullPose['Hips']; // Fire hips Left
                p2['RightUpLeg'] = fullPose['RightUpLeg']; // Pivot Rear Leg
                p2['Spine'] = fullPose['Spine']; // Start Spine turn
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 100);

            // Phase 3: THE WHIP (Arm Snap) ~240ms (Delayed Impact)
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                // OVERDRIVE: Whip slightly past center for snap
                p3['Spine'].ry -= 0.2;
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 240);

            // Phase 4: SETTLE ~350ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                window.stanceController.targetPose = fullPose;
            }, 350);

            this.lungeState = {
                startTime: Date.now(),
                duration: 700, // Slower for Counter Opportunity
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                depth: zone.includes('BODY') ? 1.4 : 1.4, // Hooks are short range
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                dynamicPose: fullPose
            };
            return;
        }

        // --- KINETIC CHAIN FOR LEFT UPPERCUT (Type 5) ---
        if (type === 5) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_5']));
            let verticalDrive = true;

            // VARIATIONS
            if (zone.includes('BODY')) { // SOLAR PLEXUS
                fullPose['Spine'].rx += 0.4; // Crunch Forward
                fullPose['LeftArm'].rx -= 0.3; // Punch more forward (shovel)
                verticalDrive = false; // Less rise on body shots
            }

            // Phase 1: THE DIP (Load ~0ms)
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_5_START']));
            window.stanceController.targetPose = p1;
            if (verticalDrive && model) model.position.y -= 0.15; // Visibly Drop

            // Phase 2: THE DRIVE (Legs Extend ~150ms)
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Hips'] = fullPose['Hips']; // Fire hips
                p2['LeftUpLeg'] = fullPose['LeftUpLeg']; // Extend Lead Leg
                p2['RightUpLeg'] = fullPose['RightUpLeg'];
                p2['Spine'] = fullPose['Spine']; // Start upward extension
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 150);

            // Phase 3: THE ARC (Impact ~300ms) - Huge Counter Window
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 300);

            // Phase 4: SETTLE
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                window.stanceController.targetPose = fullPose;
                if (model) model.position.y = 0; // Reset height
            }, 550);

            this.lungeState = {
                startTime: Date.now(),
                duration: 800, // BIG TELEGRAPH
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                startY: 0,
                depth: 1.2, // Very close range
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                verticalDrive: verticalDrive,
                dynamicPose: fullPose
            };
            return;
        }

        // --- KINETIC CHAIN FOR RIGHT UPPERCUT (Type 6) ---
        if (type === 6) {
            const fullPose = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_6']));
            let verticalDrive = true;

            // VARIATIONS
            if (zone.includes('BODY')) {
                fullPose['Spine'].rx += 0.4;
                fullPose['RightArm'].rx -= 0.3;
                verticalDrive = false;
            }

            // Phase 1: THE DIP
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['ATTACK_6_START']));
            window.stanceController.targetPose = p1;
            if (verticalDrive && model) model.position.y -= 0.15;

            // Phase 2: THE DRIVE
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Hips'] = fullPose['Hips'];
                p2['RightUpLeg'] = fullPose['RightUpLeg']; // Extend Rear Leg
                p2['LeftUpLeg'] = fullPose['LeftUpLeg'];
                p2['Spine'] = fullPose['Spine'];
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 150);

            // Phase 3: THE ARC - HUGE WINDOW
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p3 = JSON.parse(JSON.stringify(fullPose));
                if (window.stanceController) window.stanceController.targetPose = p3;
            }, 300);

            // Phase 4: SETTLE
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                window.stanceController.targetPose = fullPose;
                if (model) model.position.y = 0;
            }, 550);

            this.lungeState = {
                startTime: Date.now(),
                duration: 800, // BIG TELEGRAPH
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                startY: 0,
                depth: 1.2,
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
                verticalDrive: verticalDrive,
                dynamicPose: fullPose
            };
            return;
        }

        // STANDARD SYSTEM FOR OTHER ATTACKS
        const attackPoseName = `ATTACK_${type}`;
        const basePose = window.stanceController.poses[attackPoseName];
        if (!basePose) return;

        const dynamicPose = JSON.parse(JSON.stringify(basePose));

        if (zone.includes('BODY')) {
            dynamicPose['Spine'].rx += 0.45;
            if (type % 2 !== 0 && dynamicPose['LeftArm']) dynamicPose['LeftArm'].rx -= 0.6;
            else if (dynamicPose['RightArm']) dynamicPose['RightArm'].rx -= 0.6;
        } else if (zone.includes('LEFT')) {
            dynamicPose['Spine'].ry -= 0.25;
        } else if (zone.includes('RIGHT')) {
            dynamicPose['Spine'].ry += 0.25;
        }

        window.stanceController.targetPose = dynamicPose;
        const lungeDepth = zone.includes('BODY') ? 1.4 : 2.0;

        // Sync with Frame Perfect System
        this.lungeState = {
            startTime: Date.now(),
            duration: 400,
            startZ: (model && model.position) ? (model.position.z || 0) : 0,
            depth: lungeDepth,
            damage: damage,
            hitTriggered: false,
            isCombo: true,
            zone: zone,
            type: type, // SAVE TYPE FOR KINETIC CHAIN
            dynamicPose: dynamicPose // SAVE ADJUSTED POSE
        };
    },

    registerPlayerHit: function () {
        if (!this.playerHitLog) this.playerHitLog = [];
        const now = Date.now();
        this.playerHitLog.push(now);

        // Check for SPAM (3+ hits in < 800ms)
        const recentHits = this.playerHitLog.filter(t => now - t < 800);
        if (recentHits.length >= 3) {
            console.log("🛡️ AI: SPAM DETECTED! Forcing Guard!");

            // 1. Force Guard (Override Stun if needed for gameplay flow)
            this.isStunned = false;
            this.activateGuard();

            // 2. COUNTER WINDOW: Player can now deal bonus damage for 500ms
            this.counterWindowEnd = Date.now() + 500;
            console.log("⚡ COUNTER WINDOW OPEN!");

            // Clear log to prevent infinite trigger
            this.playerHitLog = [];
        }
    },

    cancelAttack: function () {
        if (this.isAttacking || this.lungeState) {
            console.log("🤖 AI INTERRUPTED! Entering Hit Stun...");
            this.isAttacking = false;
            this.lungeState = null; // CRITICAL: Clear lunge

            // Trigger Stun State (Opponent flinches/cannot attack)
            this.isStunned = true;
            this.stunEndTime = Date.now() + 800; // 800ms stun on interrupt

            this.comboQueue = [];
            if (window.stanceController) window.stanceController.targetPose = 'FIGHT';
            if (model) model.position.z = 0; // Immediate reset
        }
    },

    activateGuard: function () {
        if (this.isAttacking || this.isGuarding) return;

        console.log("🛡️ AI Guarding!");
        this.isGuarding = true;
        if (window.stanceController) window.stanceController.targetPose = 'GUARD';

        // Hold guard
        setTimeout(() => {
            this.isGuarding = false;
            if (!this.isAttacking && window.stanceController) window.stanceController.targetPose = 'FIGHT';
        }, 1500 + Math.random() * 1000);
    },

    shakeCamera: function (intensity) {
        // Use Global Shake System (Unified Physics)
        if (window.shakeCamera) {
            window.shakeCamera(intensity);
        } else if (window.controls) {
            // Fallback Legacy Shake
            controls.target.x += (Math.random() - 0.5) * intensity;
            controls.target.y += (Math.random() - 0.5) * intensity;
        }

        // Flash red with varying intensity
        this.flashScreen();
    },

    hitPlayer: function (damage, isCombo = true) {
        // Execute Hit Effect
        if (window.parent) window.parent.postMessage({ type: 'player_hit', damage: damage }, '*');

        // SLIP/DUCK EVASION CHECK
        if (window.isPlayerSlipping && window.isPlayerSlipping()) {
            const slip = window.getSlipDirection();
            const attackType = this.lungeState ? this.lungeState.type : 0;

            // Hooks (3,4) can be dodged by slipping left/right
            // Straights (1,2) and Uppercuts (5,6) can be dodged by ducking
            const hooksEvaded = (attackType === 3 || attackType === 4) && (slip === 'left' || slip === 'right');
            const straightsEvaded = (attackType === 1 || attackType === 2 || attackType === 5 || attackType === 6) && slip === 'duck';

            if (hooksEvaded || straightsEvaded) {
                console.log("🏃 EVADED! Attack missed!");
                // Visual feedback - green flash
                document.body.style.backgroundColor = 'rgba(0,255,100,0.15)';
                setTimeout(() => document.body.style.backgroundColor = 'transparent', 100);
                return; // MISS - no damage
            }
        }

        // DEFENSE: Reduction if player is guarding
        if (typeof isPlayerGuarding !== 'undefined' && isPlayerGuarding) {
            damage *= 0.3; // 70% reduction
            console.log("🛡️ Player Blocked Damage!");
        } else {
            // STUN PLAYER: Briefly interrupt input if not guarding
            window.isPlayerStunned = true;
            window.playerStunEndTime = Date.now() + 600; // 600ms stun
            console.log("🥊 Player Stunned!");
        }

        if (typeof playerHealth !== 'undefined') {
            playerHealth -= damage;
            if (typeof window.roundDamageTaken !== 'undefined') {
                window.roundDamageTaken += damage;
            }
            if (typeof updateGameUI === 'function') updateGameUI();

            if (playerHealth <= 0) {
                if (typeof endBoxingGame === 'function') endBoxingGame(false);
            }
        }

        // Camera Impact Shake & Flash
        if (window.controls) {
            const shake = isCombo ? 0.08 : 0.05;
            controls.target.x += (Math.random() - 0.5) * shake;
            controls.target.y += (Math.random() - 0.5) * shake;
        }
        document.body.style.backgroundColor = 'rgba(255,0,0,0.1)';
        setTimeout(() => document.body.style.backgroundColor = 'transparent', 100);
    },

    flashScreen: function () {
        const flash = document.createElement('div');
        flash.style.position = 'fixed';
        flash.style.top = '0';
        flash.style.left = '0';
        flash.style.width = '100%';
        flash.style.height = '100%';
        flash.style.background = 'radial-gradient(circle, transparent 40%, rgba(255,0,0,0.6) 100%)'; // Vignette hit effect
        flash.style.pointerEvents = 'none';
        flash.style.zIndex = '9999';
        flash.style.transition = 'opacity 0.05s'; // Instant attack
        document.body.appendChild(flash);

        // Force layout reflow
        void flash.offsetWidth;

        setTimeout(() => {
            flash.style.opacity = '0';
            setTimeout(() => flash.remove(), 150);
        }, 50); // Short flash (50ms)
    }
};
