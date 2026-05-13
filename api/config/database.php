<?php

$envFile = dirname(__DIR__, 2) . '/.env';

if (file_exists($envFile)) {
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        [$key, $value] = explode('=', $line, 2);
        $_ENV[trim($key)] = trim($value);
    }
}

$host     = $_ENV['DB_HOST']     ?? '';
$port     = $_ENV['DB_PORT']     ?? '5432';
$dbname   = $_ENV['DB_NAME']     ?? '';
$user     = $_ENV['DB_USER']     ?? '';
$password = $_ENV['DB_PASSWORD'] ?? '';

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;sslmode=require";

    $pdo = new PDO(
        $dsn,
        $user,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

} catch (PDOException $e) {
    http_response_code(500);
    die(json_encode(['error' => 'DB connection failed']));
}
