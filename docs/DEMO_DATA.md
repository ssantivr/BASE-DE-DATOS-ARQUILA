# Demo data (R04)

`scripts/seed_demo_50.sh` loads the test accounts and 50 demo projects into a local database.

Mark the local database once, by hand. Never do this on a database with real users:

```sh
psql "${DATABASE_URL/+psycopg/}" --command "ALTER DATABASE <name> SET arquila.environment = 'local'"
```

Then:

```sh
bash scripts/init.sh
bash scripts/seed_demo_50.sh
```

| Rows | Total | Per project |
|---|---|---|
| Projects | 50 | 20 architect, 20 admin, 10 viewer |
| Terrains | 50 | 1 |
| Plans | 75 | 1 or 2 |
| Rooms | 300 | 4 per plan |
| Structural components | 200 | 4 columns on the first plan |

- The same rows every time. Running it again adds nothing while the demo rows are unchanged,
  and restores the ones that are missing.
- It refuses Render, Vercel, any `ENVIRONMENT` other than development, local or test, any URL
  that is not a plain URL of this machine, and any database without the mark.
- `init.sh`, `seed.sql` and `reset_demo.sh` never load it.
- The data is fictional and only for demonstrations.

## Source of the coordinates

Only the centre of each city is used, from the coordinates of its English Wikipedia page, read on
2026-11-22 and rounded to six decimals:

- https://en.wikipedia.org/wiki/Quito
- https://en.wikipedia.org/wiki/Guayaquil
- https://en.wikipedia.org/wiki/Cuenca,_Ecuador
- https://en.wikipedia.org/wiki/Loja,_Ecuador
- https://en.wikipedia.org/wiki/Manta,_Ecuador
- https://en.wikipedia.org/wiki/Riobamba
- https://en.wikipedia.org/wiki/Ibarra,_Ecuador
- https://en.wikipedia.org/wiki/Machala
- https://en.wikipedia.org/wiki/Portoviejo
