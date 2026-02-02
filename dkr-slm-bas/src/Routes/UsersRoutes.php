<?php
namespace App\Routes;

use Slim\App;
use App\Controllers\UsersController;

class UsersRoutes
{
    public static function register(App $app): void
    {
        $app->get('/users', [UsersController::class, 'listAll']);
        $app->get('/users/{id}', [UsersController::class, 'getById']);
        $app->post('/users', [UsersController::class, 'create']);
        $app->delete('/users', [UsersController::class, 'delete']);
    }
}
