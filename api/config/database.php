<?php

$host = "aws-1-us-west-1.pooler.supabase.com";
$port = "6543";
$dbname = "postgres";

$user = "postgres.ariavoaixbgyeeixzbid";

/*
|--------------------------------------------------------------------------
| REPLACE ONLY THIS
|--------------------------------------------------------------------------
*/

$password = 'H@ppyLif3x!!$$';

try {

    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;sslmode=require";

    $pdo = new PDO(
        $dsn,
        $user,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ]
    );

    echo "Connected Successfully";

} catch (PDOException $e) {

    die($e->getMessage());

}

?>
