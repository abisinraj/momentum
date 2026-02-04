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
        easy: { cooldown: 4000, damage: 5, comboChance: 0.1, moveSpeed: 0.02 },
        medium: { cooldown: 2500, damage: 8, comboChance: 0.6, moveSpeed: 0.04 },
        hard: { cooldown: 1500, damage: 12, comboChance: 1.0, moveSpeed: 0.06 }
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
        if (typeof model !== 'undefined' && model) {
            model.position.x = 0;
            model.position.z = 0;
        }
        console.log('🤖 AI Controller Initialized (v4.0 - Combo Master)');
    },

    update: function (time) {
        if (!this.enabled || (typeof gameMode !== 'undefined' && !gameMode) || (typeof model === 'undefined' || !model)) return;

        // SAFETY: Prevent Vanishing & Drift
        if (isNaN(model.position.x) || isNaN(model.position.z)) {
            model.position.set(0, 0, 0);
        }

        // 0. HIT STUN CHECK
        if (this.isStunned) {
            if (time < this.stunEndTime) {
                return; // Cannot move or attack while stunned
            } else {
                this.isStunned = false;
            }
        }

        const pattern = this.patterns[this.difficulty];

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
            model.position.x += (offsetX - model.position.x) * smooth;
            model.position.z += (offsetZ - model.position.z) * smooth;
            model.position.y += (bobY - model.position.y) * 0.1;
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

            // KINETIC CHAIN LOGIC (For JAB - Type 1)
            if (state.type === 1) {
                // Phase 1: Windup/Hip Drive (0-20%)
                if (progress < 0.25) {
                    if (window.stanceController) window.stanceController.targetPose = 'ATTACK_1_START';
                }
                // Phase 2: Snap/Impact (25-100%)
                else {
                    // Dynamic Aim based on zone
                    if (window.stanceController) {
                        if (state.dynamicPose) {
                            window.stanceController.targetPose = state.dynamicPose;
                        } else {
                            window.stanceController.targetPose = 'ATTACK_1';
                        }
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
            const combos = [
                [1, 2], [1, 1, 2], [2, 3], [1, 2, 3], [3, 4], [5, 2], [6, 3]
            ];
            this.comboQueue = combos[Math.floor(Math.random() * combos.length)];
            console.log(`🤖 Combo: ${this.comboQueue}`);
        } else {
            this.comboQueue = [Math.floor(Math.random() * 6) + 1];
        }

        this.processComboStep(pattern.damage);
    },

    processComboStep: function (damage) {
        if (!this.comboQueue || this.comboQueue.length === 0) {
            this.isAttacking = false;
            return;
        }

        this.isAttacking = true;
        const type = this.comboQueue.shift();

        // TARGET ZONE VARIETY
        const zones = ['HEAD', 'HEAD', 'BODY', 'HEAD_LEFT', 'HEAD_RIGHT', 'BODY_LEFT', 'BODY_RIGHT'];
        const zone = zones[Math.floor(Math.random() * zones.length)];

        this.executeSingleStrike(type, damage, zone);

        let delay = 600;
        if (type === 1) delay = 400; // Fast Jab

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
            if (zone.includes('BODY')) fullPose['Spine'].rx += 0.45;

            // Phase 1: GROUND FORCE (Leaves feet, Hips start)
            // We start with the FIGHT pose but inject the lower body triggers
            const p1 = JSON.parse(JSON.stringify(window.stanceController.poses['FIGHT']));
            p1['RightUpLeg'] = fullPose['RightUpLeg'];
            p1['LeftUpLeg'] = fullPose['LeftUpLeg'];
            p1['Hips'] = fullPose['Hips']; // Hip Turn
            p1['Spine'] = window.stanceController.poses['ATTACK_1_START']['Spine']; // Lagging Spine

            window.stanceController.targetPose = p1;

            // Phase 2: KINETIC TRANSFER (Torso & Shoulder) ~60ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                const p2 = JSON.parse(JSON.stringify(p1));
                p2['Spine'] = fullPose['Spine']; // Snap Torso
                p2['LeftArm'] = fullPose['LeftArm']; // Drive Shoulder
                if (window.stanceController) window.stanceController.targetPose = p2;
            }, 60);

            // Phase 3: IMPACT (The Snap) ~100ms
            setTimeout(() => {
                if (this.isStunned || !this.lungeState) return;
                if (window.stanceController) window.stanceController.targetPose = fullPose; // Full Extension + Corkscrew
            }, 100);

            this.lungeState = {
                startTime: Date.now(),
                duration: 350, // Faster snap
                startZ: (model && model.position) ? (model.position.z || 0) : 0,
                depth: zone.includes('BODY') ? 1.4 : 2.0,
                damage: damage,
                hitTriggered: false,
                isCombo: true,
                zone: zone,
                type: type,
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
        if (window.controls) {
            // Shake target
            controls.target.x += (Math.random() - 0.5) * intensity;
            controls.target.y += (Math.random() - 0.5) * intensity;

            // Shake position (creates "head being hit" feel)
            camera.position.x += (Math.random() - 0.5) * intensity * 0.5;
        }

        // Flash red with varying intensity
        this.flashScreen();
    },

    hitPlayer: function (damage, isCombo = true) {
        // Execute Hit Effect
        if (window.parent) window.parent.postMessage({ type: 'player_hit', damage: damage }, '*');

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
