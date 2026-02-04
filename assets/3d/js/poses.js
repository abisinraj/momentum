window.STANCE_DEFINITIONS = {
    IDLE: {
        'Spine': { rx: 0, ry: 0, rz: 0 },
        'RightArm': { rx: 1.63, ry: -1.57, rz: 0.4 },  // Vertical, twisted to thigh, spread
        'LeftArm': { rx: 1.63, ry: 1.57, rz: -0.4 }, // Vertical, twisted to thigh, spread
        'RightForeArm': { rx: 0.1, ry: 0, rz: 0 },
        'LeftForeArm': { rx: 0.1, ry: 0, rz: 0 },
        'Head': { rx: 0, ry: 0, rz: 0 },
        'RightHand': { rx: 0, ry: 1.57, rz: 0 },
        'LeftHand': { rx: 0, ry: -1.57, rz: 0 },
        // Legs removed from IDLE to allow native animation
        'Fist': 0.1
    },
    FIGHT: {
        'Spine': { rx: 0.2, ry: 0, rz: 0 }, // Leaning forward slightly more
        'RightArm': { rx: 0.6, ry: -0.1, rz: -0.4 }, // Tucked elbow
        'LeftArm': { rx: 0.8, ry: 0.1, rz: 0.4 }, // Tucked elbow
        'RightForeArm': { rx: 0, ry: 0, rz: -2.0 }, // Hands up protect face
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.0 }, // Hands up protect face
        'Head': { rx: 0.1, ry: 0, rz: 0 }, // Chin tucked
        // FIX: Legs must be ~PI (3.14) to be DOWN. 0 is UP.
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 }, // Stance
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    GUARD: {
        // High Guard (Peek-a-boo)
        'Spine': { rx: 0.3, ry: 0, rz: 0 },
        'RightArm': { rx: 1.2, ry: -0.2, rz: -0.2 },
        'LeftArm': { rx: 1.2, ry: 0.2, rz: 0.2 },
        'RightForeArm': { rx: 0, ry: 0, rz: -2.3 }, // Tight to face
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.3 },
        'Head': { rx: 0.2, ry: 0, rz: 0 },
        // LEG STABILITY (Maintain Stance)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    // 1-6 BASIC STRIKES (Cinematic Reach & Eye-Level Calibration)
    ATTACK_1_START: { // JAB START (Kinetic Chain: Legs/Hips First)
        'Spine': { rx: 0.2, ry: -0.3, rz: 0 },
        'Hips': { rx: 0, ry: -0.15, rz: 0 }, // Start turning

        'LeftArm': { rx: 0.8, ry: 0.0, rz: 0.2 }, // Tucked tighter (elbow in)
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.2 },
        'Head': { rx: 0, ry: 0.2, rz: 0 },
        // LEG STABILITY FOR START (Baseline from Native IDLE ~PI)
        // Reduced flare: matching FIGHT pose exactly
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    ATTACK_1: { // JAB (Left Straight) - IMPACT PHASE
        'Spine': { rx: 0.15, ry: -0.6, rz: 0 }, // Reduced rotation (Snap, not swing)
        'Hips': { rx: 0, ry: -0.2, rz: 0 },
        'LeftArm': { rx: -0.2, ry: 1.5, rz: 1.7 }, // Shoulder high (chin protection)
        'LeftForeArm': { rx: 0, ry: 0, rz: 1.6 }, // CORKSCREW: Palm down twist
        'RightArm': { rx: 1.3, ry: -0.5, rz: -0.5 }, // Tight high guard
        'RightForeArm': { rx: 0, ry: 0, rz: -2.2 },
        // LEG STABILITY (Downwards ~PI, pivoting)
        // Minimal movement (0.05 variation max) to prevent flare
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Head': { rx: 0.1, ry: 0.4, rz: 0 }, // Chin tucked behind lead shoulder
        'Fist': 1.0
    },

    ATTACK_2: { // CROSS (Right Power)
        'Spine': { rx: 0.25, ry: 0.6, rz: 0 },
        'RightArm': { rx: -0.1, ry: -1.57, rz: -1.6 }, // Level at 1.60m
        'RightForeArm': { rx: 0, ry: 0, rz: -0.02 }, // Max extension
        'LeftArm': { rx: 1.5, ry: 0.3, rz: 0.1 }, // Guard
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.0 },
        'Head': { rx: 0, ry: -0.4, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    ATTACK_3: { // LEFT HOOK (Wide Head Strike)
        'Spine': { rx: 0.1, ry: -1.0, rz: 0 },
        'LeftArm': { rx: -0.1, ry: 1.1, rz: 1.6 }, // Level
        'LeftForeArm': { rx: 0, ry: 0, rz: 1.3 }, // Punching past center
        'RightArm': { rx: 1.5, ry: -0.3, rz: -0.1 },
        'Head': { rx: 0, ry: 0.8, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    ATTACK_4: { // RIGHT HOOK (Wide Head Strike)
        'Spine': { rx: 0.1, ry: 1.0, rz: 0 },
        'RightArm': { rx: -0.1, ry: -1.1, rz: -1.6 }, // Level
        'RightForeArm': { rx: 0, ry: 0, rz: -1.3 },
        'LeftArm': { rx: 1.5, ry: 0.3, rz: 0.1 },
        'Head': { rx: 0, ry: -0.8, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    ATTACK_5: { // LEFT UPPERCUT (Low to High)
        'Spine': { rx: -0.1, ry: -0.5, rz: -0.2 },
        'LeftArm': { rx: -0.7, ry: 0.4, rz: 0.4 },
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.2 },
        'RightArm': { rx: 1.5, ry: -0.3, rz: -0.1 },
        'Head': { rx: 0.1, ry: 0.4, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    ATTACK_6: { // RIGHT UPPERCUT (Low to High)
        'Spine': { rx: -0.1, ry: 0.5, rz: 0.2 },
        'RightArm': { rx: -0.7, ry: -0.4, rz: -0.4 },
        'RightForeArm': { rx: 0, ry: 0, rz: -2.2 },
        'LeftArm': { rx: 1.5, ry: 0.3, rz: 0.1 },
        'Head': { rx: 0.1, ry: -0.4, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0
    },
    PUNCH_RIGHT: {
        'Spine': { rx: 0.1, ry: -0.5, rz: 0.1 }, // Deeper twist
        'RightArm': { rx: -0.2, ry: -0.2, rz: -1.3 }, // Aim at camera (center)
        'LeftArm': { rx: 1.2, ry: 0.5, rz: 0.5 }, // Tight guard
        'RightForeArm': { rx: 0, ry: 0, rz: 0 }, // Fully extended
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.2 },
        'Head': { rx: 0.0, ry: -0.3, rz: 0 }, // Look at target
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0,
        lunge: 0.8 // Forward movement
    },
    PUNCH_LEFT: {
        'Spine': { rx: 0.1, ry: 0.5, rz: -0.1 },
        'RightArm': { rx: 1.2, ry: -0.5, rz: -0.5 }, // Tight guard
        'LeftArm': { rx: -0.2, ry: 0.2, rz: 1.3 }, // Aim at camera
        'RightForeArm': { rx: 0, ry: 0, rz: -2.2 },
        'LeftForeArm': { rx: 0, ry: 0, rz: 0 }, // Fully extended
        'Head': { rx: 0.0, ry: 0.3, rz: 0 },
        // LEG STABILITY (~PI)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Fist': 1.0,
        lunge: 0.8
    }
};
