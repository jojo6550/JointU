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

if ($role !== "client") {

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
    // CHECK PHONE EXISTS
    // ==================================================

    if (!empty($phone)) {

        $phoneStmt = $pdo->prepare("
            SELECT id
            FROM users
            WHERE phone = :phone
            LIMIT 1
        ");

        $phoneStmt->execute([
            ":phone" => $phone
        ]);

        if ($phoneStmt->fetch()) {

            http_response_code(409);

            echo json_encode([
                "success" => false,
                "message" => "Phone number already exists"
            ]);

            exit;
        }
    }

    // ==================================================
    // GET CLIENT ROLE ID
    // ======================================================

    $roleStmt = $pdo->prepare("
        SELECT id
        FROM roles
        WHERE role_name = 'client'
        LIMIT 1
    ");

    $roleStmt->execute();

    $roleData = $roleStmt->fetch(PDO::FETCH_ASSOC);

    if (!$roleData) {

        throw new Exception("Client role not found");
    }

    // ==================================================
    // GET FREE PLAN
    // ======================================================

    $planStmt = $pdo->prepare("
        SELECT id
        FROM membership_plans
        WHERE plan_name = 'Free'
        LIMIT 1
    ");

    $planStmt->execute();

    $planData = $planStmt->fetch(PDO::FETCH_ASSOC);

    if (!$planData) {

        throw new Exception("Free plan not found");
    }

    // ==================================================
    // HASH PASSWORD (ARGON2ID)
    // ======================================================

    $passwordHash = password_hash(
        $password,
        PASSWORD_ARGON2ID,
        [
            "memory_cost" => 65536,
            "time_cost"   => 4,
            "threads"     => 3
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
            last_name,
            display_name
        )
        VALUES (
            :user_id,
            :first_name,
            :last_name,
            :display_name
        )
    ");

    $profileStmt->execute([
        ":user_id" => $userId,
        ":first_name" => $firstName,
        ":last_name" => $lastName,
        ":display_name" => $firstName . " " . $lastName
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
    // COMMIT
    // ======================================================

    $pdo->commit();

    // ==================================================
    // SUCCESS RESPONSE
    // ======================================================

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Client account created successfully",
        "data" => [
            "user_id" => $userId,
            "email" => $email,
            "role" => "client"
        ]
    ]);

} catch (Exception $e) {

    if ($pdo->inTransaction()) {

        $pdo->rollBack();
    }

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Registration failed",
        "error" => $e->getMessage()
    ]);
}
?>