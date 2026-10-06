# BASE-DE-DATOS-ARQUILA

Esquema, migraciones y datos de ejemplo de la base de datos de ARQUILA. Es una de las tres partes del proyecto:

```text
ARQUILA
├── FRONTEND-ARQUILA        Interfaz (React)
├── BACKEND-ARQUILA         API (FastAPI)
└── BASE-DE-DATOS-ARQUILA   Este repositorio
```

## Motor

PostgreSQL 16 o superior. El SQL de este repositorio es propio de PostgreSQL.

## Contenido

```text
migrations/     Cambios del esquema, numerados y aplicados en orden
seed.sql        Datos de ejemplo (opcional)
scripts/init.sh Crea el esquema desde cero sin necesidad del backend
.env.example    Variable necesaria, sin valores reales
```

| Migración | Qué hace |
|---|---|
| `001_initial_schema.sql` | Tablas iniciales: usuarios, sesiones, proyectos, terrenos, materiales, archivos, planos, elevaciones, recomendaciones y conversaciones con la IA. |
| `002_password_reset_tokens.sql` | Tokens de recuperación de contraseña. |
| `003_terrain_points.sql` | Vértices de los lotes no rectangulares. |
| `004_ai_message_source.sql` | Origen de cada respuesta del asistente. |
| `005_rooms.sql` | Cuartos. |
| `006_structural_components.sql` | Componentes estructurales. |
| `007_recommendation_priority.sql` | Prioridad de las recomendaciones. |
| `008_element_surfaces.sql` | Materiales de superficie de cuartos y componentes. |
| `009_project_roof.sql` | Cubierta del proyecto. |
| `010_file_contents.sql` | Contenido de los archivos, para cuando el backend no puede guardarlos en disco. |

## Estructura general

Todo cuelga de `users` y de `projects`; al borrar un proyecto se borra lo que contiene.

```text
users
├── user_sessions
├── password_reset_tokens
└── projects
    ├── terrains ── terrain_points
    ├── materials
    ├── files ── file_contents
    ├── plans ─────────────┬── rooms
    │                      └── structural_components
    ├── elevations
    ├── recommendations
    └── ai_conversations ── ai_messages
```

`plans` y `elevations` pueden apuntar a un archivo de `files`. La tabla `schema_migrations` guarda qué migraciones ya se aplicaron.

Los modelos del ORM (SQLAlchemy) están en `app/models.py` de `BACKEND-ARQUILA`: son código que el backend importa, así que se mantienen allí en lugar de duplicarse. La fuente de verdad del esquema son las migraciones de este repositorio.

## Variables necesarias

| Variable | Uso |
|---|---|
| `DATABASE_URL` | Conexión a PostgreSQL, por ejemplo `postgresql+psycopg://postgres:CLAVE@localhost:5432/arquila`. |

Se define en un archivo `.env` que no se sube al repositorio. Este repositorio no contiene contraseñas ni credenciales reales.

## Crear la base desde cero

1. Crear una base vacía:

   ```bash
   psql -U postgres -c "CREATE DATABASE arquila;"
   ```

2. Aplicar las migraciones, de una de estas dos formas. Las dos registran lo aplicado en `schema_migrations`, así que se pueden combinar y repetir sin problema.

   Con el backend (forma habitual), desde `BACKEND-ARQUILA` con su `.env` configurado:

   ```bash
   python -m app.migrate          # solo el esquema
   python -m app.migrate --seed   # esquema y datos de ejemplo
   ```

   Sin el backend, solo con `psql` (en Windows, desde Git Bash):

   ```bash
   export DATABASE_URL=postgresql://postgres:CLAVE@localhost:5432/arquila
   bash scripts/init.sh          # solo el esquema
   bash scripts/init.sh --seed   # esquema y datos de ejemplo
   ```

El backend busca este repositorio en la carpeta hermana `../BASE-DE-DATOS-ARQUILA`. Si está en otro lugar, se indica con la variable `DATABASE_DIR` del backend.

## Datos de ejemplo

`seed.sql` crea un usuario de demostración con tres proyectos: `demo@example.com`, contraseña `arquila-demo`. Es una credencial pública, solo para desarrollo; en la base se guarda únicamente su hash Argon2. No cargar `seed.sql` en un entorno real.

## Añadir una migración

Crear un archivo nuevo en `migrations/` con el número siguiente (`010_descripcion.sql`). No se modifican las migraciones ya aplicadas. El cambio equivalente en los modelos va en `app/models.py` del backend.

## Comprobación automática

En cada subida a `main` y en cada pull request, GitHub crea el esquema en un PostgreSQL 16 vacío con `scripts/init.sh --seed`, lo repite para comprobar que nada se aplica dos veces y verifica que quedaron anotadas todas las migraciones (`.github/workflows/ci.yml`).

## Documentación

- `docs/BASE_DATOS.md`: diagrama entidad-relación y detalle de las migraciones.
- La documentación general del proyecto está en el repositorio [ARQUILA](https://github.com/ssantivr/ARQUILA).
