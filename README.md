# docker-linsock-services

Este repositorio contiene una colección de servicios y configuraciones Docker orientados a facilitar el despliegue y la gestión de aplicaciones que requieren comunicación eficiente mediante sockets en entornos Linux.

## ¿Qué realiza este repositorio?
- Proporciona ejemplos y plantillas para levantar servicios Dockerizados que utilizan sockets para la comunicación entre contenedores o con el sistema anfitrión.
- Permite experimentar y probar configuraciones de red y comunicación entre servicios en un entorno controlado.
- Es útil como base para desarrolladores que desean crear soluciones basadas en microservicios o sistemas distribuidos usando Docker y sockets en Linux.

---

## Organización típica de servicios dockerizados

Un proyecto con servicios dockerizados suele tener la siguiente estructura:

```
.
├── docker-compose.yml   # Archivo principal para definir y orquestar los servicios
├── servicio1/           # Carpeta con Dockerfile y configuración de un servicio
├── servicio2/           # Carpeta con Dockerfile y configuración de otro servicio
└── ...
```

Cada carpeta de servicio puede contener su propio `Dockerfile`, archivos de configuración y scripts necesarios.

---

## ¿Cómo levantar los servicios?

1. **Clona este repositorio:**
   ```zsh
   git clone https://github.com/grusso-dev/docker-linsock-services.git
   cd docker-linsock-services
   ```

2. **Asegúrate de tener Docker y Docker Compose instalados en tu sistema.**

3. **Levanta los servicios:**
   ```zsh
   docker compose up -d
   ```
   Esto construirá y levantará todos los servicios definidos en el archivo `docker-compose.yml` en modo desatendido (background).

4. **Verifica que los servicios estén corriendo:**
   ```zsh
   docker compose ps
   ```

5. **Para detener los servicios:**
   ```zsh
   docker compose down
   ```

---

## Personalización y ampliación

- Puedes agregar nuevos servicios creando nuevas carpetas y agregando sus respectivos `Dockerfile` y configuraciones.
- Modifica el archivo `docker-compose.yml` para incluir o ajustar los servicios según tus necesidades.

---

> Actualiza este README con detalles específicos de los servicios incluidos a medida que el repositorio crezca.
