# Test accounts (R02)

**Development only. These passwords are public: never create these accounts in production.**

`scripts/seed_demo_50.sh` creates them on a local database and refuses any other one. Running it
again sets the passwords back to these values.

| Role | Email | Password |
|---|---|---|
| admin | `admin@example.com` | `local-admin-2081c9a4` |
| architect | `architect@example.com` | `local-architect-75364b85` |
| viewer | `viewer@example.com` | `local-viewer-9480a069` |

The database stores only Argon2id hashes (64 MiB, 4 passes, 4 lanes).
