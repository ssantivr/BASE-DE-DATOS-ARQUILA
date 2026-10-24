# ESQUEMA

Resumen del esquema de PostgreSQL de ARQUILA tras las migraciones 001 a 027: cómo se aplican, qué tablas hay, sus claves e índices, y lo que encontró la auditoría de octubre de 2026. El diagrama entidad-relación de las tablas originales está en `docs/BASE_DATOS.md`.

## Cómo se aplican las migraciones

- Cada archivo de `migrations/` es un cambio, numerado con tres cifras y un nombre en inglés con guiones bajos (`019_tasks.sql`). Se aplican en orden alfabético, que coincide con el numérico.
- La tabla `schema_migrations (version, applied_at)` anota el nombre de cada archivo aplicado. Solo se ejecutan los que faltan, y cada uno en su propia transacción: si falla, no queda anotado.
- Dos formas de aplicarlas, que comparten `schema_migrations` y se pueden combinar:
  - `python -m app.migrate [--seed]` desde `BACKEND-ARQUILA` (lee el archivo entero y lo ejecuta con psycopg).
  - `bash scripts/init.sh [--seed]` desde este repositorio (usa `psql --single-transaction`).
- Un archivo ya aplicado no se modifica: el cambio va en un archivo nuevo. No hay migraciones de reversa.
- Ni las migraciones ni `seed.sql` pueden contener el signo de porcentaje, ni siquiera en un `RAISE` o un `LIKE`, porque psycopg lo interpreta como marcador de parámetro: con `psql` funcionaría y con `app.migrate` falla.
- Las migraciones 016 a 024 usan `IF NOT EXISTS`, `CREATE OR REPLACE` y rellenos con `WHERE ... IS NULL`, de modo que se pueden volver a ejecutar sin error y sin cambiar datos. Las 004, 007, 008 y 009 usan `ADD COLUMN` sin `IF NOT EXISTS`: no son repetibles a mano, aunque `schema_migrations` impide que se ejecuten dos veces.
- De las siguientes, la 026 se puede repetir sin efecto. La 025 también se repite sin error, pero su relleno vuelve a calcular `stage` de todos los proyectos y pisaría los cambios hechos después. La 027 no es repetible: `ADD CONSTRAINT` falla si la restricción ya existe.
- En producción, `.github/workflows/deploy.yml` aplica las pendientes con `scripts/init.sh` al fusionar en `main`.

## Tablas

34 tablas (27 antes de esta entrega, más 7 nuevas). Todas las claves primarias son `SERIAL` salvo donde se indica. Todo lo de un proyecto se borra con él (`ON DELETE CASCADE`); las referencias opcionales a usuarios, archivos, cuartos o elementos quedan vacías al borrar el destino (`ON DELETE SET NULL`).

### Usuarios y acceso

| Tabla | Clave | Relaciones | Notas |
|---|---|---|---|
| `users` | `id` | `avatar_file_id → files` | `email` único. `display_name`, `avatar_file_id` y `updated_at` desde 017/023. |
| `user_sessions` | `id` | `user_id → users` | Solo el hash del token (único). |
| `password_reset_tokens` | `id` | `user_id → users` | Ídem. |
| `roles`, `permissions` | `id` | — | Catálogos con `name` / `code` únicos. Los carga la migración 012. |
| `role_permissions` | `(role_id, permission_id)` | `roles`, `permissions` | |
| `user_roles` | `(user_id, role_id)` | `users`, `roles` | |
| `user_preferences` | `user_id` | `user_id → users` | **Nueva (023).** |
| `notifications` | `id` | `user_id → users` | **Nueva (022).** |

### Proyectos y su contenido

| Tabla | Clave | Relaciones | Notas |
|---|---|---|---|
| `projects` | `id` | `owner_id`, `created_by → users`; `cover_file_id → files` | `UNIQUE (owner_id, name)`. `status` (`draft`, `active`, `archived`), `roof`, y desde 018 `archived_at`, `cover_file_id` y `progress` (0–100). Desde 025, `project_type` (opcional) y `stage`. |
| `terrains` | `id` | `project_id` | Medidas con `CHECK` de positividad y de rango de latitud y longitud. |
| `terrain_points` | `id` | `terrain_id → terrains` | `UNIQUE (terrain_id, position)`. |
| `files` | `id` | `project_id`, `uploaded_by → users` | `project_id` opcional desde 026: vacío en una foto de perfil. `UNIQUE (id, project_id)` desde 027. |
| `file_contents` | `file_id` | `file_id → files` | Contenido binario cuando el backend no puede usar el disco. |
| `plans`, `elevations` | `id` | `project_id`, `file_id → files` | |
| `materials` | `id` | `project_id` | `UNIQUE (project_id, name)`. |
| `recommendations` | `id` | `project_id` | `source` y `priority` con `CHECK`. |
| `ai_conversations` | `id` | `project_id`, `user_id → users` | |
| `ai_messages` | `id` | `conversation_id → ai_conversations` | |
| `rooms` | `id` | `project_id`, `plan_id → plans`, `unit_id → units` | Índice GiST sobre la planta. |
| `structural_components` | `id` | `project_id`, `plan_id → plans` | |
| `properties` | `id` | `project_id` | `UNIQUE (project_id, name)`. |
| `units` | `id` | `property_id → properties` | `UNIQUE (property_id, code)`. |
| `spatial_elements` | `id` | `project_id`, `room_id → rooms` | Caja envolvente con `CHECK max > min`; índice GiST; `external_id` único por proyecto y origen. |
| `walkthrough_steps` | `id` | `project_id`, `room_id → rooms` | Paradas de la corrida de interior. |
| `renovation_logs` | `id` | `project_id`, `room_id`, `spatial_element_id`, `created_by` | |
| `tasks` | `id` | `project_id`, `assignee_id`, `created_by → users` | **Nueva (019).** |
| `project_versions` | `id` | `project_id`, `created_by → users` | **Nueva (020).** |
| `activity_log` | `id` (`BIGSERIAL`) | `project_id`, `user_id → users` | **Nueva (021).** |
| `scene_settings` | `project_id` | `project_id → projects` | **Nueva (024).** |
| `walkthrough_points` | `id` | `project_id` | **Nueva (024).** |

Desde la migración 017, además, `terrains`, `plans`, `elevations`, `materials`, `recommendations`, `rooms`, `structural_components`, `spatial_elements`, `walkthrough_steps`, `properties` y `units` tienen `created_by → users`.

### Internas del backend

| Tabla | Clave | Notas |
|---|---|---|
| `schema_migrations` | `version` | Migraciones aplicadas. |
| `runtime_state` | `(scope, key)` | Historial de «Deshacer» y límites de intentos. No tiene trigger de `updated_at`: lo escribe el backend. |

## Índices

Cada clave primaria y cada `UNIQUE` tiene su índice. Además:

| Tabla | Índices |
|---|---|
| `users` | `avatar_file_id` (parcial) |
| `user_sessions`, `password_reset_tokens` | `user_id`; `expires_at` (016, para limpiar caducados) |
| `projects` | `owner_id`; `(owner_id, status)` y `(owner_id, updated_at DESC)` (016); `(owner_id, updated_at DESC) WHERE archived_at IS NULL` y `cover_file_id` (018); `created_by` |
| `terrains`, `plans`, `elevations`, `materials`, `recommendations`, `files` | `project_id`; `plans.file_id`, `elevations.file_id` y `files.uploaded_by` (016, parciales) |
| `terrain_points` | `terrain_id` |
| `ai_conversations` | `project_id`; `user_id` (016) |
| `ai_messages` | `conversation_id`; `(conversation_id, created_at)` (016) |
| `rooms` | `project_id`, `plan_id`, `unit_id` (parcial), GiST de la planta |
| `structural_components` | `project_id`, `plan_id` |
| `properties` | `status` (016) |
| `units` | `(property_id, status)` (016) |
| `spatial_elements` | `(project_id, layer)`, `room_id` (parcial), GiST, `external_id` único parcial |
| `walkthrough_steps` | `(project_id, position)`, `room_id` (parcial) |
| `renovation_logs` | `(project_id, status)`, `room_id`, `spatial_element_id`, `created_by` (parciales) |
| `role_permissions`, `user_roles` | la segunda columna de la clave |
| `tasks` | `(project_id, status)`, `(project_id, due_date)`, `assignee_id`, `created_by` |
| `project_versions` | `UNIQUE (project_id, version_number)`, `created_by` |
| `activity_log` | `(project_id, created_at DESC)`, `(user_id, created_at DESC)`, `(entity_type, entity_id)` |
| `notifications` | `(user_id, created_at DESC)`, `user_id WHERE read_at IS NULL` |
| `walkthrough_points` | `(project_id, sort_order)` |

Todas las columnas `created_by` tienen un índice parcial `WHERE created_by IS NOT NULL`. Las claves foráneas que admiten vacío usan índices parciales, como ya hacían las migraciones 013 a 015.

Tras la migración 024, una consulta a `pg_constraint` y `pg_index` no encuentra ninguna clave foránea cuya columna no encabece un índice.

`idx_projects_owner_id` e `idx_ai_messages_conversation_id` quedan cubiertos por los índices compuestos nuevos. No se borraron, porque esta entrega no elimina nada; se pueden quitar en una migración aparte si se quiere ahorrar espacio.

## Auditoría del esquema anterior (001–015)

Resultados medidos sobre una base creada con las migraciones 001 a 015.

**Claves foráneas sin índice** (resuelto en 016): `files.uploaded_by`, `plans.file_id`, `elevations.file_id`, `ai_conversations.user_id`. Las demás ya tenían índice propio o quedaban cubiertas por una clave primaria o una restricción `UNIQUE`.

**Campos de fecha que faltaban:**

- `updated_at` solo existía en `projects`, `properties`, `units`, `renovation_logs` y `runtime_state`, y nada lo mantenía en la base: dependía del `onupdate` del ORM. Resuelto en 017 para las tablas editables y con un trigger común.
- `terrain_points` no tenía `created_at` (resuelto en 017). Tampoco lo tienen `permissions`, `role_permissions`, `user_roles` (tiene `assigned_at`), `file_contents` y `schema_migrations` (tiene `applied_at`); se dejaron así porque son catálogos, tablas de unión o el contenido de una fila que ya tiene fecha en `files`.
- Ninguna tabla registraba quién creó cada fila salvo `files.uploaded_by` y `renovation_logs.created_by` (resuelto en 017).

**Restricciones ausentes o débiles** (no se cambiaron; quedan como recomendaciones):

1. **Coherencia entre proyectos** (resuelto en 027, ver abajo). Nada impedía que un cuarto apuntara a un plano de otro proyecto, ni que `plans.file_id`, `elevations.file_id` o `projects.cover_file_id` apuntaran a un archivo de otro proyecto. Lo mismo para `room_id` en `spatial_elements`, `walkthrough_steps` y `renovation_logs`, y para `renovation_logs.spatial_element_id`.
2. **`users.email` distingue mayúsculas.** `Demo@example.com` y `demo@example.com` podrían convivir. Un índice único sobre `lower(email)` lo evitaría, pero fallaría si ya hubiera duplicados, así que conviene revisar los datos de producción antes.
3. **Dos fuentes para el archivado.** `projects.status = 'archived'` y `projects.archived_at` pueden contradecirse. La migración 018 rellena `archived_at` en los proyectos ya archivados, pero no añade un `CHECK` que los ate, para que el backend pueda adoptar `archived_at` a su ritmo.
4. **Fechas sin zona horaria.** Todo el esquema usa `TIMESTAMP`; `projects.archived_at` es `TIMESTAMPTZ` porque así se pidió. Conviven los dos tipos.
5. **Texto libre en catálogos pequeños.** `materials.unit`, `materials.category`, `recommendations.category` y `spatial_elements.kind` / `source` no tienen `CHECK`.
6. **Avatares y archivos** (resuelto en 026, ver abajo). `files.project_id` era obligatorio, así que un avatar (`users.avatar_file_id`) tenía que guardarse como archivo de algún proyecto.

## Migraciones 016 a 027

| Migración | Qué hace |
|---|---|
| `016_foreign_key_and_search_indexes.sql` | Índices en las cuatro claves foráneas que no tenían y en los campos de búsqueda y orden (estado, `updated_at`, caducidad de tokens). |
| `017_audit_columns.sql` | Función `set_updated_at()` y su trigger en todas las tablas con `updated_at` salvo `runtime_state`. Añade `updated_at`, `created_at` y `created_by` donde faltaban. |
| `018_project_archive_and_progress.sql` | `archived_at`, `cover_file_id` y `progress` en `projects`. |
| `019_tasks.sql` | Tabla `tasks`. |
| `020_project_versions.sql` | Tabla `project_versions`. |
| `021_activity_log.sql` | Tabla `activity_log`. |
| `022_notifications.sql` | Tabla `notifications`. |
| `023_user_preferences_and_profile.sql` | `display_name` y `avatar_file_id` en `users`, y tabla `user_preferences`. |
| `024_scene_settings_and_walkthrough_points.sql` | Tablas `scene_settings` y `walkthrough_points`. |
| `025_project_type_and_stage.sql` | `project_type` y `stage` en `projects`. Ver abajo. |
| `026_files_without_project.sql` | `files.project_id` pasa a ser opcional, para las fotos de perfil. Ver abajo. |
| `027_same_project_references.sql` | Claves foráneas compuestas que atan cada referencia a su proyecto. Ver abajo. |

### Cómo se rellenan los datos existentes

Ninguna migración borra ni modifica columnas que ya existían. Las columnas nuevas se rellenan así en las filas que ya estaban:

- `updated_at` toma el `created_at` de la fila, que es la última fecha conocida.
- `terrain_points.created_at` toma el `created_at` de su terreno.
- `projects.created_by` toma el `owner_id`. En las demás tablas `created_by` queda vacío, porque no se sabe quién creó cada fila.
- `projects.archived_at` toma el `updated_at` de los proyectos con `status = 'archived'`. Durante ese relleno se desactiva el trigger, para que `updated_at` no cambie.
- `projects.progress` empieza en 0.
- `projects.stage` se deduce del estado (025, ver abajo); `projects.project_type` queda vacío.

### El trigger de `updated_at`

`set_updated_at()` pone `CURRENT_TIMESTAMP` en `updated_at` en cada `UPDATE`, salvo que la propia sentencia ya le dé un valor nuevo; así no choca con el `onupdate=func.now()` del ORM, y un proceso que necesite fijar la fecha a mano puede hacerlo. Se crea con `CREATE OR REPLACE TRIGGER`, que existe desde PostgreSQL 14.

## Migración 025: tipo y etapa del proyecto

`025_project_type_and_stage.sql` añade dos columnas a `projects`:

| Columna | Tipo | Valores | Por defecto |
|---|---|---|---|
| `project_type` | `VARCHAR(20)`, opcional | `house`, `apartment_building`, `commercial`, `mixed_use` (el vocabulario de `properties.property_type`) | vacío |
| `stage` | `VARCHAR(20) NOT NULL` | `draft`, `in_progress`, `completed`, `archived` | `draft` |

- `stage` es el ciclo de vida explícito del proyecto. `status` (`draft`, `active`, `archived`) se mantiene con sus valores para los clientes que ya lo usan.
- Los proyectos que ya existían toman la etapa que describen sus datos, en este orden: `archived` si `status = 'archived'` o tienen `archived_at`; si no, `completed` si `progress = 100`; si no, `in_progress` si `status = 'active'`; y si no, `draft`. El trigger de `updated_at` se desactiva durante ese relleno, como en 018.
- Índices: `(owner_id, stage)` para listar por etapa, y `(owner_id, project_type) WHERE project_type IS NOT NULL`.
- Nada ata `stage` con `status` ni con `archived_at`, igual que pasa entre `status` y `archived_at` (recomendación 3). Hoy el backend solo declara las dos columnas en `app/models.py`: ningún endpoint las lee ni las escribe, así que un proyecto nuevo queda en `draft` aunque se cree como `active`.

## Migración 026: archivos sin proyecto

`026_files_without_project.sql` hace opcional `files.project_id` (`ALTER COLUMN project_id DROP NOT NULL`). Un archivo sin proyecto es una foto de perfil: pertenece al usuario que la subió (`uploaded_by`, con índice desde 016) y se enlaza desde `users.avatar_file_id`.

Cómo lo usa el backend:

- `POST /auth/me/avatar` sube la foto como archivo sin proyecto. Solo acepta PNG, JPEG o WebP, detectados por sus primeros bytes.
- Solo su dueño puede abrirla o borrarla. Cuando se sube otra foto, o se quita la actual, el backend borra la anterior siempre que fuera un archivo sin proyecto del mismo usuario. Si el avatar era un archivo de un proyecto, ese archivo se conserva.
- Al borrar un proyecto, el backend vacía `avatar_file_id` de quien usara uno de sus archivos como foto. En la base, `users.avatar_file_id` ya tenía `ON DELETE SET NULL` (023).
- Desde 027, un archivo sin proyecto no puede ser plano, alzado ni portada: su `project_id` vacío no coincide con el de ningún proyecto.

Queda abierto: `files.uploaded_by` es `ON DELETE SET NULL`. Si un día se borra un usuario, sus fotos se quedarían sin proyecto y sin dueño, sin que nadie pudiera abrirlas ni borrarlas. Hoy no hay forma de borrar una cuenta, pero cuando la haya tendrá que borrar antes esas fotos. `CHECK (project_id IS NOT NULL OR uploaded_by IS NOT NULL)` haría que la base lo exigiera.

## Migración 027: referencias dentro del mismo proyecto

`027_same_project_references.sql` añade `UNIQUE (id, project_id)` en `plans`, `rooms`, `spatial_elements` y `files`, y claves foráneas compuestas junto a las simples, que se mantienen:

| Referencia | Clave compuesta | Al borrar el destino |
|---|---|---|
| `rooms.plan_id` | `(plan_id, project_id) → plans` | `CASCADE` |
| `structural_components.plan_id` | `(plan_id, project_id) → plans` | `CASCADE` |
| `spatial_elements.room_id` | `(room_id, project_id) → rooms` | `SET NULL (room_id)` |
| `walkthrough_steps.room_id` | `(room_id, project_id) → rooms` | `SET NULL (room_id)` |
| `renovation_logs.room_id` | `(room_id, project_id) → rooms` | `SET NULL (room_id)` |
| `renovation_logs.spatial_element_id` | `(spatial_element_id, project_id) → spatial_elements` | `SET NULL (spatial_element_id)` |
| `plans.file_id` | `(file_id, project_id) → files` | `SET NULL (file_id)` |
| `elevations.file_id` | `(file_id, project_id) → files` | `SET NULL (file_id)` |
| `projects.cover_file_id` | `(cover_file_id, id) → files` | `SET NULL (cover_file_id)` |

- `SET NULL (columna)` vacía solo la referencia y deja `project_id`, que es `NOT NULL`. Necesita PostgreSQL 15 o posterior (el CI usa 16).
- Con `MATCH SIMPLE`, el valor por defecto, una referencia vacía no se comprueba: las columnas opcionales siguen admitiendo `NULL`.
- Un archivo sin proyecto (un avatar, desde 026) no puede ser plano, alzado ni portada, porque su `project_id` vacío no coincide con el de ningún proyecto.
- Antes de crear las claves, la migración cuenta las filas que apuntan a otro proyecto y, si hay alguna, se detiene con la lista (`Rows that point at another project: rooms.plan_id: 1`) en lugar de fallar en la primera restricción.

**En el backend**, `app/models.py` declara las mismas 13 restricciones con los mismos nombres, para que `create_all` (los tests con SQLite) cree el mismo esquema:

- SQLite no admite `SET NULL (columna)`, así que allí esas claves compuestas se crean sin acción al borrar. La clave simple de la misma columna ya la vacía, y con una columna vacía la compuesta no se comprueba: el resultado es el mismo que en PostgreSQL.
- `tests/conftest.py` activa `PRAGMA foreign_keys=ON`; sin él SQLite no comprueba ninguna clave foránea.
- Las relaciones `Plan.rooms`, `Plan.components`, `Room.spatial_elements`, `Room.walkthrough_steps`, `Room.renovation_logs` y `SpatialElement.renovation_logs` indican `foreign_keys`, para que la clave compuesta no les haga copiar `project_id` del padre.
- `Project.id` declara `autoincrement=True`: al formar parte de la clave de la portada, SQLAlchemy dejaba de numerarlo por sí solo.
- «Deshacer» (`undo_history.column_values`) solo omite en una fila hija la referencia a la clave primaria del padre. Antes omitía cualquier columna con clave foránea hacia el padre, y desde 027 eso incluía `rooms.project_id`: al deshacer el borrado de un plano, sus cuartos se habrían restaurado sin proyecto.

Se probó el 21 de octubre de 2026 en un PostgreSQL 18.6 local y temporal: 001 a 027 con `seed.sql`, seis referencias cruzadas rechazadas (cuarto, componente, portada, plano con archivo ajeno, avatar como portada y elemento espacial), los borrados en cascada y a `NULL`, y el aviso previo con `psql` y con psycopg. La suite del backend pasa entera (477 tests) tanto en SQLite con las claves foráneas activadas como en PostgreSQL con `TEST_DATABASE_URL`, y los nombres de las 13 restricciones coinciden entre `app/models.py` y la base migrada.

## Tablas nuevas

### `tasks` — tareas de un proyecto

Pendientes del equipo: `title`, `description`, `status` (`todo`, `in_progress`, `done`), `assignee_id`, `due_date` y `progress` (0–100). Un `CHECK` exige `progress = 100` cuando `status = 'done'`. Lleva `created_by`, `created_at` y `updated_at`. Al borrar al responsable, la tarea queda sin asignar.

### `project_versions` — versiones guardadas

Una foto del proyecto en un momento dado: `version_number` (único por proyecto, mayor que 0), `label` y `snapshot` (JSONB, siempre un objeto). El contenido de `snapshot` lo decide el backend. No tiene `updated_at` porque una versión no se edita.

### `activity_log` — registro de actividad

Una fila por acción: `action` (por ejemplo `task.created`), y opcionalmente `entity_type` y `entity_id` de lo afectado, más `detail` (JSONB). `project_id` es opcional para registrar acciones que no son de un proyecto, como un inicio de sesión. Si se indica `entity_id` hay que indicar `entity_type`. Usa `BIGSERIAL` porque es la tabla que más crece. Si se borra el usuario, sus acciones se conservan sin autor; si se borra el proyecto, se borran con él.

### `notifications` — avisos para un usuario

`title`, `body` y `read_at` (vacío mientras no se lea). El índice parcial sobre las no leídas hace barato el contador de la campana.

### `user_preferences` — preferencias de la interfaz

Una fila por usuario como máximo (`user_id` es la clave): `theme` (`light`, `dark`, `auto`), `units` (`metric`, `imperial`), `density` (`compact`, `comfortable`, `spacious`), `reduce_motion`, `camera_defaults` (JSONB), `preview_quality` (`low`, `medium`, `high`) y `notifications` (JSONB con qué avisos quiere recibir). Todo tiene valor por defecto, así que basta con insertar el `user_id`. Los valores permitidos de `density` y `preview_quality` no venían en el encargo: se eligieron estos y se cambian con una migración nueva si la interfaz usa otros.

### `scene_settings` — escena 3D del proyecto

Una fila por proyecto como máximo: `lighting` (JSONB, objeto) y `camera_presets` (JSONB, lista de cámaras guardadas).

### `walkthrough_points` — puntos de recorrido

Puntos de cámara con nombre, ordenados por `sort_order`. `position` y `target` son listas `[x, y, z]` en metros, el mismo formato que las cámaras de `walkthrough_steps.view_config`. Se solapa en parte con `walkthrough_steps`, que ya guarda una cámara por parada: `walkthrough_points` sirve para puntos de vista sueltos, sin cuarto, duración ni texto. Conviene decidir en el backend cuál de las dos usa cada pantalla.

## Datos de ejemplo

`seed.sql` sigue creando al usuario `demo@example.com` (contraseña `arquila-demo`) con los mismos tres proyectos, y ahora además:

- `display_name` «Demo» y una fila en `user_preferences`.
- Progreso de los proyectos: 35, 10 y 5.
- Seis tareas repartidas entre los tres proyectos, en los tres estados.
- Tres versiones (dos de «Casa Los Arrayanes», una de «Edificio Mirador»). Su `snapshot` resume lo que el propio seed creó: estado, cubierta y número de planos, cuartos, componentes y materiales.

Todo es de demostración. Se puede cargar varias veces sin duplicar nada, y `scripts/reset_demo.sh` lo borra junto con el usuario porque todo cuelga de él o de sus proyectos.

## Verificación

Hecha el 20 de octubre de 2026 en un PostgreSQL 18.6 local y temporal (el CI usa PostgreSQL 16; no se probó en 16).

- **Base vacía**, con los mismos pasos que `.github/workflows/ci.yml`: `scripts/init.sh --seed` dos veces, borrado de un proyecto y `scripts/reset_demo.sh`. Se aplicaron las 24 migraciones y quedaron 3 proyectos, 6 tareas, 3 versiones y 1 fila de preferencias.
- **Base con el esquema anterior**: migraciones 001 a 015 y el `seed.sql` anteriores (tomados de `HEAD`), más datos de prueba de otro usuario con fechas antiguas, archivos, conversación, sesión y estado de «Deshacer». Antes y después de aplicar 016 a 024 se calculó, para cada una de las 26 tablas anteriores, el número de filas y un md5 de todas las filas sobre las columnas que ya existían. Las 26 huellas coinciden: no cambió ningún dato. Ningún proyecto archivado quedó sin `archived_at` y ningún proyecto sin `created_by`. Después, el seed nuevo dos veces y `reset_demo.sh`, que no tocó el proyecto del otro usuario.
- **Restricciones**: se rechazan 13 casos inválidos (progreso fuera de rango, estado o tema desconocido, tarea terminada al 50, versión repetida o 0, JSON del tipo equivocado, un punto con dos coordenadas, etc.).
- **Trigger**: un `UPDATE` sin `updated_at` lo actualiza, y uno que lo fija conserva el valor dado.
- **Repetición**: cada migración 016 a 024 se volvió a ejecutar a mano sobre la base ya migrada, sin error.
- **Backend**: `python -m app.migrate --seed` dos veces sobre una base vacía; la contraseña de demostración se valida con `app.security.verify_password`; y la suite de `BACKEND-ARQUILA` pasa entera (333 tests) contra PostgreSQL con `TEST_DATABASE_URL`, que aplica estas migraciones.
