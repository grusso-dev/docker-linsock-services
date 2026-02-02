<?php
use Slim\Factory\AppFactory;
use DI\ContainerBuilder;
use Doctrine\DBAL\Connection;
use App\Database\ConnectionFactory;
use App\Routes\UsersRoutes;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

require __DIR__ . '/../vendor/autoload.php';

// Crear contenedor de dependencias
$containerBuilder = new ContainerBuilder();
$containerBuilder->addDefinitions([
    // Mapear Doctrine\DBAL\Connection a ConnectionFactory
    Connection::class => function () {
        return ConnectionFactory::create();
    }
]);

// Crear app con contenedor
AppFactory::setContainer($containerBuilder->build());
$app = AppFactory::create();

// Ruta raíz
$app->get('/', function (Request $request, Response $response) {
    $response->getBody()->write("🚀 Slim 4 con Doctrine DBAL y estructura organizada");
    return $response;
});

// Registrar rutas externas
UsersRoutes::register($app);

// Ejecutar aplicación
$app->run();
