<?php

header("Content-Type: application/json");

require_once "../config/database.php";

// ======================================================
// ONLY ALLOW POST
// ======================================================

if ($_SERVER["REQUEST_METHOD"] !== "POST") {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Method not allowed"
    ]);

    exit;
}

// ======================================================
// GET JSON INPUT
// ======================================================

$data = json_decode(file_get_contents("php://input"), true);

// ======================================================
// REQUIRED FIELDS
// ======================================================

$requiredFields = [
    "first_name",
    "last_name",
    "email",
    "password",
    "role"
];

foreach ($requiredFields as $field) {

    if (
        !isset($data[$field]) ||
        empty(trim($data[$field]))
    ) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "$field is required"
        ]);

        exit;
    }
}

// ======================================================
// CLEAN INPUTS
// ======================================================

$firstName = trim($data["first_name"]);
$lastName  = trim($data["last_name"]);
$email     = trim($data["email"]);
$phone     = trim($data["phone"] ?? "");
$password  = trim($data["password"]);
$role      = trim($data["role"]);

$skills        = $data["skills"] ?? [];
$serviceAreas  = $data["service_areas"] ?? [];
$customSkill   = trim($data["custom_skill"] ?? "");

// ======================================================
// VALIDATE EMAIL
// ======================================================

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid email address"
    ]);

    exit;
}

// ======================================================
// PASSWORD VALIDATION
// ======================================================

if (strlen($password) < 8) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Password must be at least 8 characters"
    ]);

    exit;
}

// ======================================================
// VALIDATE ROLE
// ======================================================

if ($role !== "worker") {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid role"
    ]);

    exit;
}

try {

    // ==================================================
    // CHECK EMAIL EXISTS
    // ==================================================

    $checkStmt = $pdo->prepare("
        SELECT id
        FROM users
        WHERE email = :email
        LIMIT 1
    ");

    $checkStmt->execute([
        ":email" => $email
    ]);

    if ($checkStmt->fetch()) {

        http_response_code(409);

        echo json_encode([
            "success" => false,
            "message" => "Email already exists"
        ]);

        exit;
    }

    // ==================================================
    // GET WORKER ROLE ID
    // ==================================================

    $roleStmt = $pdo->prepare("
        SELECT id
        FROM roles
        WHERE role_name = 'worker'
        LIMIT 1
    ");

    $roleStmt->execute();

    $roleData = $roleStmt->fetch(PDO::FETCH_ASSOC);

    // ==================================================
    // GET FREE PLAN
    // ==================================================

    $planStmt = $pdo->prepare("
        SELECT id
        FROM membership_plans
        WHERE plan_name = 'Free'
        LIMIT 1
    ");

    $planStmt->execute();

    $planData = $planStmt->fetch(PDO::FETCH_ASSOC);

    // ==================================================
    // HASH PASSWORD USINg AGON2ID
    // ======================================================

   $passwordHash = password_hash(
    $password,
    PASSWORD_ARGON2ID,
    [
        'memory_cost' => 65536,
        'time_cost'   => 4,
        'threads'     => 3
    ]
    );

    // ==================================================
    // START TRANSACTION
    // ======================================================

    $pdo->beginTransaction();

    // ==================================================
    // INSERT USER
    // ======================================================

    $userStmt = $pdo->prepare("
        INSERT INTO users (
            role_id,
            plan_id,
            email,
            phone,
            password_hash
        )
        VALUES (
            :role_id,
            :plan_id,
            :email,
            :phone,
            :password_hash
        )
        RETURNING id
    ");

    $userStmt->execute([
        ":role_id" => $roleData["id"],
        ":plan_id" => $planData["id"],
        ":email" => $email,
        ":phone" => !empty($phone) ? $phone : null,
        ":password_hash" => $passwordHash
    ]);

    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    $userId = $user["id"];

    // ==================================================
    // CREATE PROFILE
    // ======================================================

    $profileStmt = $pdo->prepare("
        INSERT INTO user_profiles (
            user_id,
            first_name,
            last_name
        )
        VALUES (
            :user_id,
            :first_name,
            :last_name
        )
    ");

    $profileStmt->execute([
        ":user_id" => $userId,
        ":first_name" => $firstName,
        ":last_name" => $lastName
    ]);

    // ==================================================
    // CREATE WALLET
    // ======================================================

    $walletStmt = $pdo->prepare("
        INSERT INTO user_wallets (
            user_id
        )
        VALUES (
            :user_id
        )
    ");

    $walletStmt->execute([
        ":user_id" => $userId
    ]);

    // ==================================================
    // CREATE MEMBERSHIP
    // ======================================================

    $membershipStmt = $pdo->prepare("
        INSERT INTO user_memberships (
            user_id,
            plan_id,
            start_date,
            status
        )
        VALUES (
            :user_id,
            :plan_id,
            CURRENT_DATE,
            'active'
        )
    ");

    $membershipStmt->execute([
        ":user_id" => $userId,
        ":plan_id" => $planData["id"]
    ]);

    // ==================================================
    // INSERT USER SKILLS
    // ======================================================

    if (!empty($skills)) {

        foreach ($skills as $skillName) {

            $skillStmt = $pdo->prepare("
                SELECT id
                FROM skills
                WHERE name = :name
                LIMIT 1
            ");

            $skillStmt->execute([
                ":name" => $skillName
            ]);

            $skillData = $skillStmt->fetch(PDO::FETCH_ASSOC);

            if ($skillData) {

                $insertSkill = $pdo->prepare("
                    INSERT INTO user_skills (
                        user_id,
                        skill_id
                    )
                    VALUES (
                        :user_id,
                        :skill_id
                    )
                ");

                $insertSkill->execute([
                    ":user_id" => $userId,
                    ":skill_id" => $skillData["id"]
                ]);
            }
        }
    }

    // ==================================================
    // INSERT SERVICE AREAS
    // ======================================================

    if (!empty($serviceAreas)) {

        foreach ($serviceAreas as $area) {

            $areaStmt = $pdo->prepare("
                INSERT INTO worker_service_areas (
                    user_id,
                    state_parish
                )
                VALUES (
                    :user_id,
                    :state_parish
                )
            ");

            $areaStmt->execute([
                ":user_id" => $userId,
                ":state_parish" => $area
            ]);
        }
    }

    // ==================================================
    // STORE CUSTOM SKILL
    // ======================================================

    if (!empty($customSkill)) {

        $pendingStmt = $pdo->prepare("
            INSERT INTO pending_skills (
                user_id,
                skill_name
            )
            VALUES (
                :user_id,
                :skill_name
            )
        ");

        $pendingStmt->execute([
            ":user_id" => $userId,
            ":skill_name" => $customSkill
        ]);
    }

    // ==================================================
    // COMMIT
    // ======================================================

    $pdo->commit();

    // ==================================================
    // SUCCESS
    // ======================================================

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Worker account created successfully",
        "data" => [
            "user_id" => $userId,
            "email" => $email
        ]
    ]);

} catch (PDOException $e) {

    $pdo->rollBack();

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Registration failed",
        "error" => $e->getMessage()
    ]);
}
?>