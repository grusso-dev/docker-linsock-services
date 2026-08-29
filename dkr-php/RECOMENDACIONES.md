# Recomendaciones pendientes

Este archivo reúne mejoras sugeridas que todavía no forman parte de la configuración activa. Deben aplicarse después de medir el comportamiento de las aplicaciones en las máquinas de destino.

## Ajustar PHP-FPM para equipos con poca memoria

Estado: **pendiente, no aplicado**.

PHP-FPM administra los procesos que ejecutan las peticiones PHP. Su configuración predeterminada puede mantener varios procesos en memoria aunque el tráfico sea bajo. Como punto de partida para equipos con recursos limitados, se propone:

```ini
[www]

pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 500
```

### Propósito de cada opción

- `pm = ondemand`: crea procesos PHP cuando llegan peticiones, reduciendo el consumo de memoria mientras la aplicación está inactiva. La primera petición después de un período sin actividad puede tener una pequeña latencia adicional.
- `pm.max_children = 5`: limita a cinco la cantidad de peticiones PHP que pueden ejecutarse simultáneamente. Las peticiones adicionales esperan hasta que quede disponible un proceso.
- `pm.process_idle_timeout = 10s`: finaliza procesos que llevan diez segundos inactivos para recuperar memoria.
- `pm.max_requests = 500`: recicla cada proceso después de 500 peticiones, reduciendo el impacto acumulado de posibles fugas de memoria en PHP o sus extensiones.

### Cómo aplicarlo en el futuro

Crear `php/zz-resource-limits.conf` con la configuración anterior y copiarlo desde ambos Dockerfiles:

```dockerfile
COPY zz-resource-limits.conf /usr/local/etc/php-fpm.d/zz-resource-limits.conf
```

El prefijo `zz-` permite que el archivo se cargue después de la configuración predeterminada del pool `www`.

### Validación necesaria

El valor `pm.max_children = 5` es un punto de partida. Antes de adoptarlo en producción se debe medir la memoria promedio de los procesos PHP-FPM y probar la concurrencia esperada. Un límite demasiado alto puede agotar la memoria; uno demasiado bajo puede generar esperas durante picos de tráfico.
