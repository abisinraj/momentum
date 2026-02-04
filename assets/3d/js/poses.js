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
        'Spine': { rx: 0.15, ry: -0.8, rz: 0 }, // MORE Rotation (Drive the shoulder)
        'Hips': { rx: 0, ry: -0.3, rz: 0 }, // MORE Hip Turn
        // Upper Arm: Aimed straight forward. rx: elevation, ry: yaw, rz: twist/roll
        'LeftArm': { rx: -0.1, ry: 0.3, rz: 1.4 }, // Adjusted to match PUNCH_LEFT geometry but higher
        'LeftForeArm': { rx: 0, ry: 0, rz: 0 }, // PURE Extension (0.0). No twist here to avoid bone deformation.
        'RightArm': { rx: 1.3, ry: -0.5, rz: -0.5 }, // Tight high guard
        'RightForeArm': { rx: 0, ry: 0, rz: -2.2 },
        // LEG STABILITY (Downwards ~PI, pivoting)
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightLeg': { rx: -0.15, ry: 0, rz: 0 },
        'LeftLeg': { rx: -0.23, ry: 0, rz: 0 },
        'Head': { rx: 0.1, ry: 0.6, rz: 0 }, // Chin tucked
        'LeftHand': { rx: 0, ry: 0, rz: 1.57 }, // Corkscrew happens at the WRIST/HAND
        'Fist': 1.0
    },

    ATTACK_2_START: { // CROSS WINDUP (Rear Foot Load)
        'Spine': { rx: 0.2, ry: 0.1, rz: 0 },
        'Hips': { rx: 0, ry: 0.05, rz: 0 }, // Slight cocking back
        'RightArm': { rx: 0.6, ry: -0.1, rz: -0.4 }, // Tight
        'LeftArm': { rx: 0.8, ry: 0.1, rz: 0.4 }, // Tight Guard
        // Rear Leg Loaded (Right)
        'RightUpLeg': { rx: 0.06, ry: -0.3, rz: 3.01 }, // Knee in slightly
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'Fist': 1.0
    },
    ATTACK_2: { // CROSS (Right Straight) - IMPACT PHASE
        'Spine': { rx: 0.25, ry: 0.9, rz: 0 }, // MAX Rotation
        'Hips': { rx: 0, ry: 0.4, rz: 0 }, // Hips fully committed
        'RightArm': { rx: -0.1, ry: -0.3, rz: -1.4 }, // Shoulder Driven Forward
        'RightForeArm': { rx: 0, ry: 0, rz: 0 }, // FULL EXTENSION
        'LeftArm': { rx: 1.4, ry: 0.4, rz: 0.4 }, // High Guard
        'LeftForeArm': { rx: 0, ry: 0, rz: 2.2 },
        'Head': { rx: 0.1, ry: -0.6, rz: 0 }, // Eyes fixed on target
        // Power Pivot (Right Heel visualization relies on bone map)
        'RightUpLeg': { rx: 0.2, ry: -0.4, rz: 3.1 }, // Pivot in
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'RightHand': { rx: 0, ry: 0, rz: -1.57 }, // Corkscrew Palm Down
        'Fist': 1.0
    },
    ATTACK_3_START: { // LEFT HOOK LOAD
        'Spine': { rx: 0.1, ry: -0.3, rz: 0 }, // Rotate Left (Cock back)
        'Hips': { rx: 0, ry: -0.2, rz: 0 },
        'LeftArm': { rx: 0.8, ry: 0.1, rz: 0.4 }, // Loose/Ready
        'RightArm': { rx: 0.6, ry: -0.1, rz: -0.4 }, // Guard
        // Weight on Lead Leg
        'LeftUpLeg': { rx: -0.1, ry: 0.2, rz: -3.06 },
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 },
        'Fist': 1.0
    },
    ATTACK_3: { // LEFT HOOK (Wide Head Strike) - IMPACT
        'Spine': { rx: 0.1, ry: 0.8, rz: 0 }, // WHIP Right
        'Hips': { rx: 0, ry: 0.5, rz: 0 }, // Hips Lead
        'LeftArm': { rx: -0.2, ry: 1.0, rz: 1.5 }, // Elbow High (90 deg structure)
        'LeftForeArm': { rx: 0, ry: 0, rz: 1.57 }, // 90 Degree Hook
        'RightArm': { rx: 1.4, ry: -0.5, rz: -0.4 }, // High Block Right
        // LEAD LEG PIVOT ("Squash the Bug")
        'LeftUpLeg': { rx: 0.1, ry: 0.6, rz: -3.06 }, // Significant Pivot Inward
        'RightUpLeg': { rx: 0.06, ry: -0.2, rz: 3.01 }, // Anchor Rear
        'Head': { rx: 0, ry: -0.3, rz: 0 }, // Eyes on target
        'LeftHand': { rx: 0, ry: 0, rz: 1.57 }, // Palm Down/In
        'Fist': 1.0
    },
    ATTACK_4_START: { // RIGHT HOOK LOAD
        'Spine': { rx: 0.1, ry: 0.3, rz: 0 }, // Cock Right
        'Hips': { rx: 0, ry: 0.2, rz: 0 },
        'RightArm': { rx: 0.8, ry: -0.1, rz: -0.4 }, // Loose/Ready
        'LeftArm': { rx: 0.6, ry: 0.1, rz: 0.4 }, // Guard
        // Weight on Rear Leg
        'RightUpLeg': { rx: 0, ry: -0.4, rz: 3.01 },
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 },
        'Fist': 1.0
    },
    ATTACK_4: { // RIGHT HOOK (Wide Head Strike) - IMPACT
        'Spine': { rx: 0.1, ry: -0.7, rz: 0 }, // WHIP Left
        'Hips': { rx: 0, ry: -0.4, rz: 0 }, // Hips Lead Left
        'RightArm': { rx: -0.2, ry: -1.0, rz: -1.5 }, // Elbow High (90 deg structure)
        'RightForeArm': { rx: 0, ry: 0, rz: -1.57 }, // 90 Degree Hook
        'LeftArm': { rx: 1.4, ry: 0.5, rz: 0.4 }, // High Guard Left
        // REAR LEG PIVOT ("Squash the Bug")
        'RightUpLeg': { rx: 0.2, ry: -0.6, rz: 3.1 }, // Significant Pivot Inward
        'LeftUpLeg': { rx: -0.04, ry: 0.2, rz: -3.06 }, // Post Lead Leg
        'Head': { rx: 0, ry: 0.3, rz: 0 }, // Eyes on target
        'RightHand': { rx: 0, ry: 0, rz: -1.57 }, // Palm Down/In
        'Fist': 1.0
    },
    ATTACK_5_START: { // LEFT UPPERCUT LOAD (The Dip)
        'Spine': { rx: 0.2, ry: -0.4, rz: -0.2 }, // Deep Crunch Left/Back (Coil)
        'Hips': { rx: 0.1, ry: -0.1, rz: 0 },
        'LeftArm': { rx: 1.0, ry: 0, rz: 0.1 }, // Dropped/Tucked
        'RightArm': { rx: 0.6, ry: -0.1, rz: -0.4 }, // Guard
        // DEEP KNEE BEND (Loading)
        'RightUpLeg': { rx: -0.3, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.4, ry: 0.2, rz: -3.06 },
        'Fist': 1.0
    },
    ATTACK_5: { // LEFT UPPERCUT - IMPACT
        'Spine': { rx: -0.2, ry: 0.6, rz: 0.2 }, // Extended UP & Right
        'Hips': { rx: -0.1, ry: 0.4, rz: 0 }, // Thrust Hips
        'LeftArm': { rx: -1.0, ry: 0.5, rz: 0.8 }, // Driving UP
        'LeftForeArm': { rx: 0.5, ry: 0, rz: 1.8 }, // Cup Shape
        'RightArm': { rx: 1.4, ry: -0.5, rz: -0.4 }, // High Block Right
        // LEG EXTENSION (The Drive)
        'LeftUpLeg': { rx: 0.1, ry: 0.4, rz: -3.06 },
        'RightUpLeg': { rx: 0, ry: -0.2, rz: 3.01 },
        'Head': { rx: 0.2, ry: -0.2, rz: 0 }, // Chin Tucked
        'LeftHand': { rx: 0, ry: 0, rz: 0 }, // Palm Up
        'Fist': 1.0
    },
    ATTACK_6_START: { // RIGHT UPPERCUT LOAD (The Dip)
        'Spine': { rx: 0.2, ry: 0.4, rz: 0.2 }, // Deep Crunch Right/Back (Coil)
        'Hips': { rx: 0.1, ry: 0.1, rz: 0 },
        'RightArm': { rx: 1.0, ry: 0, rz: -0.1 }, // Dropped/Tucked
        'LeftArm': { rx: 0.6, ry: 0.1, rz: 0.4 }, // Guard
        // DEEP KNEE BEND (Loading) ["Spring"]
        'RightUpLeg': { rx: -0.4, ry: -0.2, rz: 3.01 },
        'LeftUpLeg': { rx: -0.3, ry: 0.2, rz: -3.06 },
        'Fist': 1.0
    },
    ATTACK_6: { // RIGHT UPPERCUT - IMPACT
        'Spine': { rx: -0.2, ry: -0.6, rz: -0.2 }, // Extended UP & Left
        'Hips': { rx: -0.1, ry: -0.4, rz: 0 }, // Thrust Hips Left
        'RightArm': { rx: -1.0, ry: -0.5, rz: -0.8 }, // Driving UP
        'RightForeArm': { rx: 0.5, ry: 0, rz: -1.8 }, // Cup Shape
        'LeftArm': { rx: 1.4, ry: 0.5, rz: 0.4 }, // High Guard Left
        // REAR LEG PIVOT + DRIVE
        'RightUpLeg': { rx: 0.1, ry: -0.6, rz: 3.1 }, // Pivot & Extend
        'LeftUpLeg': { rx: 0, ry: 0.2, rz: -3.06 },
        'Head': { rx: 0.2, ry: 0.2, rz: 0 },
        'RightHand': { rx: 0, ry: 0, rz: 0 }, // Palm Up
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
    },

    // === KNOCKDOWN: Yamcha Death Pose ===
    // The iconic defeated pose from Dragon Ball
    // Key: Lying on SIDE in fetal position, one arm reaching forward
    KNOCKDOWN: {
        // CORE: Lying on side, curled fetal position (Yamcha Scale)
        // Back (Magenta) facing up, lying on Left side
        'Hips': { rx: -1.4, ry: 3.14, rz: -1.57 },
        'Spine': { rx: 0.9, ry: 0.2, rz: 0.1 },
        'Head': { rx: 0.5, ry: 0.6, rz: -0.4 },

        'LeftArm': { rx: -1.2, ry: 0.5, rz: 0.8 },
        'LeftForeArm': { rx: -1.5, ry: 0, rz: 0 },
        'RightArm': { rx: 0.8, ry: -0.4, rz: -1.2 },
        'RightForeArm': { rx: -1.8, ry: 0, rz: -0.5 },

        'RightUpLeg': { rx: 2.1, ry: -0.2, rz: -2.8 },
        'LeftUpLeg': { rx: 1.2, ry: 0.4, rz: 2.6 },
        'RightLeg': { rx: 2.2, ry: 0, rz: 0 },
        'LeftLeg': { rx: 2.0, ry: 0, rz: 0 },

        'Fist': 0.2
    }
};
