window.stanceController = {
    activePose: 'IDLE',
    targetPose: 'IDLE',
    bones: {},
    lastHitTime: 0,
    guardTimer: null,
    poses: window.STANCE_DEFINITIONS || {}, // Link to loaded poses

    init: function () {
        // Refresh poses in case they loaded after this script
        if (window.STANCE_DEFINITIONS) {
            this.poses = window.STANCE_DEFINITIONS;
        }

        console.log("🥊 Procedural Controller: Mapping Skeleton...");

        const searchGroups = {
            'Spine': ['Spine2', 'Spine1', 'Chest', 'Spine', 'Hips'],
            'RightArm': ['RightArm', 'UpperArm_R', 'Arm_R', 'mixamorigRightArm'],
            'LeftArm': ['LeftArm', 'UpperArm_L', 'Arm_L', 'mixamorigLeftArm'],
            'RightForeArm': ['RightForeArm', 'ForeArm_R', 'LowerArm_R', 'mixamorigRightForeArm'],
            'LeftForeArm': ['LeftForeArm', 'ForeArm_L', 'LowerArm_L', 'mixamorigLeftForeArm'],
            'Head': ['Head', 'Neck', 'mixamorigHead'],
            'Hips': ['Hips', 'Pelvis', 'mixamorigHips'],
            'RightUpLeg': ['RightUpLeg', 'UpLeg_R', 'Right_UpLeg', 'mixamorigRightUpLeg'],
            'LeftUpLeg': ['LeftUpLeg', 'UpLeg_L', 'Left_UpLeg', 'mixamorigLeftUpLeg'],
            'RightLeg': ['RightLeg', 'Leg_R', 'Right_Leg', 'mixamorigRightLeg'],
            'LeftLeg': ['LeftLeg', 'Leg_L', 'Left_Leg', 'mixamorigLeftLeg'],
            'RightFoot': ['RightFoot', 'Foot_R', 'Right_Foot', 'mixamorigRightFoot'],
            'LeftFoot': ['LeftFoot', 'Foot_L', 'Left_Foot', 'mixamorigLeftFoot'],
            'RightHand': ['RightHand', 'Hand_R', 'Right_Hand', 'mixamorigRightHand'],
            'LeftHand': ['LeftHand', 'Hand_L', 'Left_Hand', 'mixamorigLeftHand']
        };

        const fingerBases = ['Index', 'Middle', 'Ring', 'Pinky', 'Thumb'];
        const joints = ['1', '2', '3']; // Find all 3 joints for better curling

        for (let logicalName in searchGroups) {
            let found = null;
            for (let term of searchGroups[logicalName]) {
                found = findBone(term);
                if (found) break;
            }

            if (found) {
                this.bones[logicalName] = {
                    ref: found,
                    currentRot: found.rotation.clone(),
                    recoil: new THREE.Vector3(0, 0, 0),
                    velocity: new THREE.Vector3(0, 0, 0),
                    cameraShake: 0
                };

                if (logicalName.includes('Hand')) {
                    const side = logicalName.includes('Right') ? 'Right' : 'Left';
                    this.bones[logicalName].fingers = [];
                    console.log(`🔍 Searching fingers for ${logicalName}...`);

                    fingerBases.forEach((base) => {
                        joints.forEach(j => {
                            // Try patterns: RightHandIndex1, RightIndex1, mixamorigRightHandIndex1
                            let fingerBone = findBone(side + 'Hand' + base + j) ||
                                findBone(side + base + j) ||
                                findBone('mixamorig' + side + 'Hand' + base + j) ||
                                findBone('mixamorig' + side + base + j);

                            if (fingerBone) {
                                console.log(`   ✓ Found finger joint: ${fingerBone.name}`);
                                this.bones[logicalName].fingers.push({
                                    ref: fingerBone,
                                    originalRot: fingerBone.rotation.clone(),
                                    jointLevel: parseInt(j)
                                });
                            }
                        });
                    });
                }
            }
        }
        const rFin = this.bones['RightHand'] ? this.bones['RightHand'].fingers.length : 0;
        const lFin = this.bones['LeftHand'] ? this.bones['LeftHand'].fingers.length : 0;
        console.log(`🥊 Stance Controller: Found R:${rFin} L:${lFin} finger joints`);
        this.targetPose = 'IDLE'; // Default to relaxed
        console.log("🥊 Stance Controller Ready (v6.3 - RELAXED IDLE)");

        // Debug visuals removed for production
    },
    addBoneDebugVisuals: function () {
        const geom = new THREE.SphereGeometry(0.05, 8, 8);
        for (let name in this.bones) {
            const bone = this.bones[name].ref;
            let color = 0x888888;
            if (name.includes('Head')) color = 0xFF0000;
            else if (name.includes('Hand')) color = 0xFFFF00;
            else if (name.includes('Foot')) color = 0xFFA500;
            else if (name.includes('Leg')) color = 0x800080;
            else if (name.includes('Arm')) color = 0x00FF00;
            else if (name.includes('Spine') || name.includes('Hips')) color = 0x0000FF;

            const mesh = new THREE.Mesh(geom, new THREE.MeshBasicMaterial({ color: color, depthTest: false }));
            mesh.renderOrder = 999;
            bone.add(mesh);
        }
    },
    triggerHit: function (muscle, point, isCritical) {
        const baseForce = isCritical ? 2.2 : 0.9; // Reduced from 1.8/3.5 to fix "throw off"

        // --- BOXING PHYSICS ENGINE (1-6 Strikes & Body Zones) ---
        let reactionType = 'GENERIC';
        let side = 'CENTER';

        if (point) {
            // Side: x > 0.05 (Left), x < -0.05 (Right)
            if (point.x > 0.05) side = 'LEFT_SIDE'; // Model's Left
            else if (point.x < -0.05) side = 'RIGHT_SIDE'; // Model's Right
            else side = 'CENTER';

            const absX = Math.abs(point.x);

            // Height (Y)
            if (point.y > 1.48) {
                // High Head
                if (side === 'CENTER') reactionType = 'UPPERCUT_HEAD';
                else reactionType = 'HOOK_HEAD';
            } else if (point.y > 1.32) {
                // Face
                if (absX > 0.12) reactionType = 'HOOK_HEAD';
                else reactionType = 'STRAIGHT_HEAD';
            } else if (point.y > 1.15) {
                // Chest
                reactionType = 'BODY_CHEST';
            } else if (point.y > 0.95) {
                // Abs/Obliques
                if (absX > 0.15) reactionType = 'BODY_OBLIQUE';
                else reactionType = 'BODY_ABS';
            } else {
                // Low
                reactionType = 'BODY_LOW';
            }
        }

        let turnDir = 0;
        if (side === 'LEFT_SIDE') turnDir = -1.0;
        if (side === 'RIGHT_SIDE') turnDir = 1.0;

        console.log(`🥊 Hit: ${reactionType} on ${side}`);

        if (reactionType.includes('HEAD') && this.bones['Head']) {
            const b = this.bones['Head'];

            if (reactionType === 'UPPERCUT_HEAD') {
                // 5 & 6: Snap Head UP/BACK
                b.velocity.x -= baseForce * 1.5;
                b.velocity.y += (Math.random() - 0.5) * 0.5;
                if (this.bones['Spine']) this.bones['Spine'].velocity.y += 0.08;
            }
            else if (reactionType === 'HOOK_HEAD') {
                // 3 & 4: Violent Spin
                b.velocity.y += turnDir * baseForce * 1.8;
                b.velocity.z -= turnDir * baseForce * 0.4;
                b.velocity.x -= baseForce * 0.3;
            }
            else if (reactionType === 'STRAIGHT_HEAD') {
                // 1 & 2: Snap Back
                b.velocity.x -= baseForce * 1.2;
                b.velocity.y += turnDir * baseForce * 0.6;
            }
        }

        else if (reactionType.includes('BODY') && this.bones['Spine']) {
            const b = this.bones['Spine'];

            if (reactionType === 'BODY_CHEST') {
                b.velocity.z -= baseForce * 0.4;
                b.velocity.x -= baseForce * 0.3;
                // Fix: Add directional twist away from hit
                // Hit Left -> Turn Right (turnDir = -1)
                if (turnDir !== 0) b.velocity.y += turnDir * baseForce * 0.5;
            }
            else if (reactionType === 'BODY_ABS') {
                b.velocity.x += baseForce * 1.0;
                b.velocity.y -= 0.05;
                if (this.bones['Head']) this.bones['Head'].velocity.x += baseForce * 0.5;
            }
            else if (reactionType === 'BODY_OBLIQUE') {
                // Fix: Sway AWAY from hit
                const sway = (side === 'LEFT_SIDE') ? -1.0 : 1.0;
                b.velocity.z += sway * baseForce * 0.8;
                b.velocity.x += baseForce * 0.4;

                // Subtle Hip Sway (0.2) - Grounded but reactive
                if (this.bones['Hips']) {
                    this.bones['Hips'].velocity.z += sway * 0.2;
                    this.bones['Hips'].velocity.y -= 0.02;
                }
            }
            else if (reactionType === 'BODY_LOW') {
                if (this.bones['Hips']) {
                    // Reduced rotation significantly (0.5 -> 0.15) to anchor feet
                    this.bones['Hips'].velocity.z += turnDir * baseForce * 0.15;
                    this.bones['Hips'].velocity.x -= 0.2;
                }
            }
        }

        if (this.bones['Spine']) this.bones['Spine'].cameraShake = isCritical ? 0.35 : 0.15;
    },
    update: function (time) {
        if (!model || Object.keys(this.bones).length === 0) return;

        // RESTORED: Breathing & Fatigue (Safe)
        const breathing = Math.sin(time * 0.002) * (this.targetPose === 'IDLE' ? 0.012 : 0.005);
        const fatigue = (typeof modelHealth !== 'undefined') ? Math.max(0, (100 - modelHealth) / 100) : 0;

        // === DAMAGE STATES: Visual Degradation ===
        // State thresholds: 75%, 50%, 25%
        let damageState = 'healthy';
        if (fatigue > 0.25) damageState = 'hurt'; // < 75% HP
        if (fatigue > 0.5) damageState = 'wounded'; // < 50% HP  
        if (fatigue > 0.75) damageState = 'critical'; // < 25% HP

        // Fatigue Effects (Enhanced based on state)
        if (this.bones['Head']) {
            let chinLift = fatigue * 0.45;
            // Critical: Add wobble
            if (damageState === 'critical') {
                chinLift += Math.sin(time * 0.004) * 0.15;
            }
            this.bones['Head'].ref.rotation.x -= chinLift;
        }
        if (this.bones['Spine']) {
            let slump = fatigue * 0.2;
            // Wounded+: Add sway
            if (damageState === 'wounded' || damageState === 'critical') {
                slump += Math.sin(time * 0.003) * 0.08;
            }
            this.bones['Spine'].ref.rotation.x += slump;
            // Critical: Side lean
            if (damageState === 'critical') {
                this.bones['Spine'].ref.rotation.z += Math.sin(time * 0.002) * 0.1;
            }
        }

        // Visual: Red overlay based on damage (apply to model material)
        if (model && fatigue > 0.5 && typeof gameMode !== 'undefined' && gameMode) {
            // Simple body tint via CSS for now (non-invasive)
            const canvas = document.querySelector('canvas');
            if (canvas) {
                const tintIntensity = Math.min(0.3, (fatigue - 0.5) * 0.6);
                canvas.style.filter = `saturate(${1 - tintIntensity}) sepia(${tintIntensity * 0.5})`;
            }
        } else {
            const canvas = document.querySelector('canvas');
            if (canvas) canvas.style.filter = '';
        }

        // === AI HEAD MOVEMENT (Bob & Weave) ===
        // Only apply during FIGHT stance when not actively attacking
        if (this.targetPose === 'FIGHT' && typeof gameMode !== 'undefined' && gameMode) {
            const t = time * 0.001; // Slow time scale

            // Head bob (side-to-side weave)
            if (this.bones['Head']) {
                const headWeave = Math.sin(t * 1.5) * 0.08; // Slow weave
                const headBob = Math.sin(t * 2.2) * 0.04; // Subtle vertical
                this.bones['Head'].ref.rotation.y += headWeave;
                this.bones['Head'].ref.rotation.x += headBob;
            }

            // Slight spine rotation for "peek-a-boo" style
            if (this.bones['Spine']) {
                const spineWeave = Math.sin(t * 1.2) * 0.05;
                this.bones['Spine'].ref.rotation.y += spineWeave;
            }
        }

        // PHYSICS TUNING: "Heavy Bag" Feel
        // PHYSICS TUNING: CONSTANT SAFE MODE
        const stiffness = 0.03; // Smoother transitions (from 0.04)
        const damping = 0.82; // Higher damping to prevent break-dancing oscillations (from 0.75)

        for (let name in this.bones) {
            const boneData = this.bones[name];
            const activeP = this.targetPose;
            const poseData = (typeof activeP === 'object') ? activeP : (this.poses[activeP] || this.poses['IDLE']);
            const target = poseData ? poseData[name] : null;

            if (target) {
                boneData.currentRot.x += (target.rx - boneData.currentRot.x) * stiffness;
                boneData.currentRot.y += (target.ry - boneData.currentRot.y) * stiffness;

                // FIX: Shortest path interpolation for Z (Rotation)
                let diffZ = target.rz - boneData.currentRot.z;
                if (diffZ > Math.PI) diffZ -= Math.PI * 2;
                if (diffZ < -Math.PI) diffZ += Math.PI * 2;
                boneData.currentRot.z += diffZ * stiffness;
            }

            // Physics damping and clamping
            boneData.velocity.multiplyScalar(damping);
            boneData.recoil.add(boneData.velocity);

            // BRING BACK: Recoil spring (pull back to zero)
            boneData.recoil.x -= boneData.recoil.x * 0.1;
            boneData.recoil.y -= boneData.recoil.y * 0.1;
            boneData.recoil.z -= boneData.recoil.z * 0.1;

            // CLAMP: Prevent bones from snapping 360 degrees
            const maxRecoil = 0.8; // radians (~45 deg)
            boneData.recoil.x = Math.max(-maxRecoil, Math.min(maxRecoil, boneData.recoil.x));
            boneData.recoil.y = Math.max(-maxRecoil, Math.min(maxRecoil, boneData.recoil.y));
            boneData.recoil.z = Math.max(-maxRecoil, Math.min(maxRecoil, boneData.recoil.z));

            // NaN SAFETY
            let rx = boneData.currentRot.x + boneData.recoil.x;
            let ry = boneData.currentRot.y + boneData.recoil.y;
            let rz = boneData.currentRot.z + boneData.recoil.z;

            if (isNaN(rx) || isNaN(ry) || isNaN(rz)) {
                boneData.currentRot.set(0, 0, 0);
                boneData.recoil.set(0, 0, 0);
                boneData.velocity.set(0, 0, 0);
                rx = 0; ry = 0; rz = 0;
            }

            if (target) {
                boneData.ref.rotation.set(rx, ry, rz);
            }

            if (name === 'Spine' && boneData.cameraShake > 0.001) {
                // More stable shake
                controls.target.x += (Math.random() - 0.5) * boneData.cameraShake;
                controls.target.y += (Math.random() - 0.5) * boneData.cameraShake;
                boneData.cameraShake *= 0.7; // Faster decay
                if (boneData.cameraShake <= 0.001) {
                    controls.target.set(0, 1, 0);
                }
            }

            // --- Procedural "Noise" for Life ---
            const t = time * 0.0005;
            if (name === 'Spine') {
                boneData.ref.rotation.x += breathing; // Main breathing
                boneData.ref.rotation.y += Math.sin(t * 3.1) * 0.02; // Micro twisting
            }
            if (name === 'Head') {
                // Look around slightly
                boneData.ref.rotation.y += Math.sin(t * 4.5) * 0.03;
                boneData.ref.rotation.x += Math.cos(t * 3.5) * 0.02;
            }
            if (name.includes('Arm')) {
                boneData.ref.rotation.x += breathing * 0.4;
                // Uneven arm sway
                const offset = name.includes('Right') ? 0 : 2;
                boneData.ref.rotation.z += Math.sin(t * 2 + offset) * 0.01;
            }

            // UPDATED: Advanced Anatomical Grip
            if (boneData.fingers) {
                const activeP = this.targetPose;
                const poseData = (typeof activeP === 'object') ? activeP : (this.poses[activeP] || this.poses['IDLE']);
                const amount = (poseData && poseData.Fist !== undefined) ? poseData.Fist : 0;
                const isRight = name.includes('Right');
                const sideSig = isRight ? -1 : 1;

                boneData.fingers.forEach(f => {
                    const fname = f.ref.name.toLowerCase();
                    const isThumb = fname.includes('thumb');

                    // Reset everything first
                    f.ref.scale.set(1, 1, 1);

                    if (amount < 0.1) {
                        // Return to rest pose smoothly
                        f.ref.rotation.x += (f.originalRot.x - f.ref.rotation.x) * 0.1;
                        f.ref.rotation.y += (f.originalRot.y - f.ref.rotation.y) * 0.1;
                        f.ref.rotation.z += (f.originalRot.z - f.ref.rotation.z) * 0.1;
                        return;
                    }

                    // --- FIST 6.0: The "Avalanche" Scale (Depth & Axis Fix) ---
                    // 1. Staggered Z (Curl): Pinky curls much deeper than Index to create a slope.
                    // 2. Swapped Spread Axis: Moving convergence from Y (Twist) to X (Spread).

                    const FIST_ANGLES = {
                        'Thumb': {
                            // Thumb is special, uses all axes
                            1: { x: 0.3, y: 0.5, z: 0.6 }, // CMC: Fold across
                            2: { x: -0.1, y: 0.0, z: 0.8 }, // MCP: Bend
                            3: { x: 0.0, y: 0.0, z: 1.5 }   // IP: Hook tip
                        },
                        'Index': {
                            // KNUCKLE: High & Proud (The "peak" of the fist ridge)
                            1: { x: -0.15, y: 0.0, z: 1.3 }, // X: Flare OUT (Spread), Z: Less Curl
                            2: { x: 0.0, y: 0.0, z: 1.8 },
                            3: { x: 0.0, y: 0.0, z: 0.6 }
                        },
                        'Middle': {
                            1: { x: 0.0, y: 0.0, z: 1.5 }, // Baseline
                            2: { x: 0.0, y: 0.0, z: 1.9 },
                            3: { x: 0.0, y: 0.0, z: 0.7 }
                        },
                        'Ring': {
                            1: { x: 0.1, y: 0.0, z: 1.7 }, // X: Converge IN, Z: Deeper
                            2: { x: 0.0, y: 0.0, z: 2.1 },
                            3: { x: 0.0, y: 0.0, z: 0.8 }
                        },
                        'Pinky': {
                            // KNUCKLE: Buried & Cupped (The bottom of the slope)
                            1: { x: 0.25, y: 0.0, z: 2.0 }, // X: Strong Cup IN, Z: Max Curl
                            2: { x: 0.0, y: 0.0, z: 2.2 }, // Compact
                            3: { x: 0.0, y: 0.0, z: 0.9 }
                        }
                    };

                    let type = '';
                    if (isThumb) type = 'Thumb';
                    else if (fname.includes('index')) type = 'Index';
                    else if (fname.includes('middle')) type = 'Middle';
                    else if (fname.includes('ring')) type = 'Ring';
                    else if (fname.includes('pinky')) type = 'Pinky';

                    if (type && FIST_ANGLES[type] && FIST_ANGLES[type][f.jointLevel]) {
                        const tgt = FIST_ANGLES[type][f.jointLevel];

                        let targetX, targetY, targetZ;

                        if (type === 'Thumb') {
                            const thumbScale = amount;
                            const tBend = tgt.z * thumbScale;
                            const tRoll = tgt.x * thumbScale;
                            const tYaw = tgt.y * thumbScale;

                            targetX = f.originalRot.x + (tRoll * sideSig);
                            targetY = f.originalRot.y + (tYaw * sideSig);
                            targetZ = f.originalRot.z + (tBend * sideSig * -1.0); // INVERTED Z
                        } else {
                            const tx = tgt.x * sideSig;
                            const ty = tgt.y * sideSig;
                            const tz = tgt.z;

                            targetX = f.originalRot.x + (tz * amount);  // Curl
                            targetY = f.originalRot.y + (ty * amount);  // Spread
                            targetZ = f.originalRot.z + (tx * amount);  // Twist
                        }

                        f.ref.rotation.x += (targetX - f.ref.rotation.x) * 0.2;
                        f.ref.rotation.y += (targetY - f.ref.rotation.y) * 0.2;
                        f.ref.rotation.z += (targetZ - f.ref.rotation.z) * 0.2;
                    }

                    // Volume Scale (Keep subtle)
                    if (f.jointLevel === 2 && !type.includes('Thumb')) {
                        const s = 1.0 + (amount * 0.08);
                        f.ref.scale.set(s, s, s);
                    }
                });
            }
        }

        // Camera Tracking
        if (window.controls && model) {
            const targetY = gameMode ? 1.45 : 1.0;
            const lerpSpeed = 0.05;

            controls.target.x += (model.position.x - controls.target.x) * lerpSpeed;
            controls.target.z += (model.position.z - controls.target.z) * lerpSpeed;
            controls.target.y += (targetY - controls.target.y) * lerpSpeed;
        }
    }
};
