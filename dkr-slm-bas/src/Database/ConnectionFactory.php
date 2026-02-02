<?php
namespace App\Database;

use Doctrine\DBAL\DriverManager;
use Doctrine\DBAL\Connection;

class ConnectionFactory
{
    public static function create(): Connection
    {
        $connectionParams = [
            'dbname'   => 'Admision',
            'user'     => 'sa',
            'password' => 'TuPassword123!',
            'host'     => '192.168.0.248',
            'port'     => 1433,
            'driver'   => 'pdo_sqlsrv',
            'driverOptions' => [
                "TrustServerCertificate" => true
            ],
        ];

        return DriverManager::getConnection($connectionParams);
    }
}
