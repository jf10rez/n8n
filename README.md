# n8n Docker Environment with PostgreSQL Backend

Este repositorio contiene la configuración Docker y Docker Compose para desplegar un entorno de automatización **n8n** consistente, seguro y optimizado para entornos locales o de producción, utilizando **PostgreSQL 16** como motor de persistencia.

---

## Características de este Diseño

1. **Persistencia mediante PostgreSQL:** En lugar de SQLite, este entorno implementa una base de datos PostgreSQL dedicada, previniendo bloqueos de base de datos bajo cargas de trabajo concurrentes o flujos complejos.
2. **Dockerfile Personalizado:**
   - Construido sobre la imagen oficial optimizada de n8n (`docker.n8n.io/n8nio/n8n`).
   - Incluye utilidades comunes instaladas a nivel de sistema (`curl`, `jq`, `git`, `openssh-client`, `python3`, `py3-pip`, `bash`) para permitir scripting avanzado dentro del nodo *Execute Command*.
3. **Seguridad Integrada:**
   - El contenedor de n8n corre bajo el usuario no-raíz (`node`).
   - La base de datos PostgreSQL no expone puertos al exterior (aislamiento de red), comunicándose de manera interna y exclusiva con n8n mediante una red dedicada (`n8n_net`).
   - Todas las credenciales críticas se gestionan a través de variables de entorno seguras (`.env`).
4. **Mantenimiento Autónomo:**
   - Configuración integrada de autopoda (*pruning*) de logs de ejecución viejos para prevenir el llenado del disco.

---

## Requisitos Previos

- Tener instalado **Docker** y **Docker Compose** (V2).
- Tener un terminal compatible con `bash`.

---

## Guía de Inicio Rápido

### Paso 1: Clonar/Preparar las variables de entorno
Copia la plantilla de variables de entorno a un archivo real `.env`:
```bash
cp .env.example .env
```

### Paso 2: Generar la Clave de Encriptación
n8n requiere una clave para encriptar las contraseñas de las integraciones que configures en la base de datos. Genera una cadena aleatoria segura usando:
```bash
openssl rand -hex 24
```
Abre tu archivo `.env` recién creado y reemplaza los placeholders con la clave generada y con contraseñas seguras para PostgreSQL:
```env
N8N_ENCRYPTION_KEY=tu_clave_generada_aqui
POSTGRES_PASSWORD=tu_contrasena_segura_aqui
N8N_DB_POSTGRESDB_PASSWORD=tu_contrasena_segura_aqui  # Debe ser idéntica a la anterior
```

*Nota: También puedes cambiar el puerto (`N8N_PORT`, por defecto `5678`) y la zona horaria (`GENERIC_TIMEZONE`) si es necesario.*

### Paso 3: Iniciar el Entorno
Ejecuta el siguiente comando para compilar la imagen personalizada de n8n y levantar los servicios en segundo plano:
```bash
docker compose up --build -d
```

### Paso 4: Validar el estado
Comprueba que ambos contenedores estén levantados y saludables:
```bash
docker compose ps
```
Deberías ver una salida indicando que `n8n_app` y `n8n_postgres` están `Up (healthy)`.

Para inspeccionar los logs de inicio y verificar la conexión exitosa a la base de datos:
```bash
docker compose logs -f n8n
```

¡Listo! Ya puedes abrir tu navegador e ingresar a: **[http://localhost:5678](http://localhost:5678)**.

---

## Comandos Útiles de Administración

### Levantar y detener servicios
*   **Iniciar el entorno:** `docker compose up -d`
*   **Detener el entorno (preservando datos):** `docker compose down`
*   **Detener el entorno y limpiar volúmenes de datos (Peligro: borra base de datos):** `docker compose down -v`

### Monitoreo
*   **Ver logs en tiempo real:** `docker compose logs -f`
*   **Ver uso de recursos (CPU/RAM):** `docker stats`

### Actualizaciones
Para actualizar n8n a la versión más reciente disponible río arriba:
```bash
docker compose pull
docker compose up --build -d
```

---

## Estrategia de Respaldos (Backups)

Es vital respaldar la base de datos de n8n regularmente para evitar pérdidas catastróficas.

### Generar un respaldo de la base de datos
Para exportar toda la base de datos PostgreSQL a un archivo en tu máquina local:
```bash
docker exec -t n8n_postgres pg_dump -U n8n_admin n8n_db > backup_n8n_$(date +%F).sql
```

### Restaurar un respaldo
Para restaurar una base de datos guardada a partir de un archivo `.sql`:
```bash
# 1. Asegúrate de que el contenedor de postgres esté corriendo
# 2. Vuelca el respaldo en la base de datos
docker exec -i n8n_postgres psql -U n8n_admin n8n_db < backup_n8n_XXXX-XX-XX.sql
```

---

## Personalizaciones Adicionales (Opcional)

Si requieres instalar librerías específicas de Python para usarlas dentro del código de n8n (ej. `pandas`, `requests`):
1. Abre el archivo `Dockerfile`.
2. Descomenta la línea de instalación de pip y añade tus librerías:
   ```dockerfile
   RUN pip3 install --no-cache-dir --upgrade pip requests pandas
   ```
3. Recompila e inicia:
   ```bash
   docker compose up --build -d
   ```
