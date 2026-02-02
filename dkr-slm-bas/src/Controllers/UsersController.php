<?php
namespace App\Controllers;

use Doctrine\DBAL\Connection;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class UsersController
{
    private Connection $db;

    public function __construct(Connection $db)
    {
        $this->db = $db;
    }

    /**
     * Método privado para ejecutar el Stored Procedure
     */
    private function callStoredProcedure(array $params): array
    {
        $sql = "EXEC HHR_EMP_STR " . implode(", ", array_map(
            fn($key) => "@$key = :$key",
            array_keys($params)
        ));

        $stmt = $this->db->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }

        $result = $stmt->executeQuery();
        return $result->fetchAllAssociative();
    }

    /**
     * Listar empleados (op = 05)
     */
    public function listAll(Request $request, Response $response): Response
    {
        $buscod = $request->getQueryParams()['buscod'] ?? 'HBOCALANDRO';

        $rows = $this->callStoredProcedure([
            'lp_opr'    => '08',
            'lp_usr'    => 'grusso',
            'lp_buscod' => $buscod
        ]);

        $response->getBody()->write(json_encode($rows));
        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * Obtener un empleado por ID (op = 03)
     */
    public function getById(Request $request, Response $response, array $args): Response
{
    $buscod = $request->getQueryParams()['buscod'] ?? 'HBOCALANDRO';
    $id = $args['id'] ?? null;

    $rows = $this->callStoredProcedure([
        'lp_opr'    => '03',
        'lp_usr'    => 'grusso',
        'lp_buscod' => $buscod,
        'lp_empcod' => $id
    ]);

    $response->getBody()->write(json_encode($rows));
    return $response->withHeader('Content-Type', 'application/json');
}


    /**
     * Alta de empleado (op = 01)
     */
    public function create(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody() ?? [];

        $rows = $this->callStoredProcedure(array_merge($data, [
            'lp_opr' => '01',
            'lp_usr' => $data['lp_usr'] ?? 'grusso',
        ]));

        $response->getBody()->write(json_encode($rows));
        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * Baja de empleado (op = 04)
     */
    public function delete(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody() ?? [];

        $rows = $this->callStoredProcedure([
            'lp_opr'    => '04',
            'lp_usr'    => $data['lp_usr'] ?? 'grusso',
            'lp_buscod' => $data['lp_buscod'] ?? 'HBOCALANDRO',
            'lp_empcod' => $data['lp_empcod'] ?? null,
            'lp_docsts' => $data['lp_docsts'] ?? 'I', // estado de baja
        ]);

        $response->getBody()->write(json_encode($rows));
        return $response->withHeader('Content-Type', 'application/json');
    }
}
