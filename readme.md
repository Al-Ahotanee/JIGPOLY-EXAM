# JIGPOLY Polytechnic OIRMF

**Online Incident Reporting and Management Framework**

JIGPOLY Polytechnic OIRMF is a PHP 8.3 monolithic web application for reporting, reviewing, tracking, and resolving examination-malpractice incidents. The application includes role-aware dashboards for administrators, examination officers, invigilators, Heads of Department, and committee members.

## Technology and deployment model

| Area | Implementation |
|---|---|
| Web application | PHP 8.3 with Apache |
| Frontend | React 18, Axios, Tailwind CSS, and Chart.js loaded from CDNs |
| Database | PostgreSQL through PDO_PGSQL |
| Managed database | Neon PostgreSQL using `DATABASE_URL` and SSL |
| Hosting | Render Web Service using the included Dockerfile |
| Schema setup | Safe, idempotent startup migration in `api.php` |
| Authentication | PHP sessions, bcrypt passwords, role-based access control, and session-bound CSRF tokens |

The application no longer depends on MySQL. The database schema uses PostgreSQL-compatible `BIGSERIAL`, `TIMESTAMPTZ`, boolean fields, check constraints, and PostgreSQL date functions.

## Important free-hosting limitation

Render Free services have an ephemeral filesystem. Uploaded evidence files stored under `uploads/` can disappear after a restart, redeploy, or spin-down. The Neon database persists relational records, but it is not a file/object-storage service. For production evidence retention, add an object-storage service and store its permanent URL in `incident_evidence`; do not treat the Render filesystem as permanent storage. Render Free services also spin down after inactivity and may take about a minute to wake up. See the official Render Free documentation for the current limits [1].

## Files

| File | Purpose |
|---|---|
| `api.php` | PostgreSQL connection, schema migration, seed accounts, authentication, CSRF protection, and API actions |
| `index.php` | Public landing page and login/registration interface |
| `admin.php` | Administrator dashboard and user/college/department/course management |
| `eo.php` | Examination-officer dashboard and reports |
| `users.php` | Invigilator, HOD, and committee dashboards |
| `Dockerfile` | Render-ready PHP 8.3 Apache image with `pdo_pgsql` |
| `render.yaml` | Optional Render Blueprint configuration |
| `.gitignore` | Prevents credentials, environment files, and uploaded files from entering Git |

## 1. Create the Neon database

Create a free Neon project at [neon.tech](https://neon.tech), create or select a database, and copy the connection string from Neon. It normally begins with `postgresql://` and contains the host, database, user, password, and SSL parameters. The application accepts the complete connection string through `DATABASE_URL`; it also supports `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, and `PGPASSWORD` for local development. Neon documents PDO PostgreSQL connections and the `pdo_pgsql` driver in its PHP guide [2].

Do not commit the connection string to GitHub. Treat it as a secret.

## 2. Upload the corrected code to GitHub

Create a new empty GitHub repository, then run the following commands from the project directory:

```bash
git init
git add .
git commit -m "Prepare JIGPOLY OIRMF for PostgreSQL and Render"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

Before pushing, confirm that `.env` files, database URLs, passwords, and real uploaded evidence are not included. The initial demo credentials are defined in `api.php` and should be changed in the source before production use.

## 3. Deploy the web service on Render

In Render, select **New → Web Service**, connect the GitHub repository, and choose the **Free** plan. Because this repository includes a `Dockerfile`, select Docker/runtime autodetection or Docker explicitly. Render will build the image, install PHP's PostgreSQL extension, and serve Apache on port 80.

Set only the following environment variables in Render. The `DATABASE_URL` value must be the Neon connection string copied from Neon. Session security automatically follows `APP_ENV=production`.

| Variable | Value |
|---|---|
| `DATABASE_URL` | Neon PostgreSQL connection string; mark as secret |
| `APP_ENV` | `production` |

Set the health-check path to `/api.php?action=health`. After deployment, open the Render URL and wait for the service to wake if it has been idle. The first request to `api.php` creates the tables and inserts seed data if the database is empty.

The included `render.yaml` can also be used as a Render Blueprint. You only need to enter the secret `DATABASE_URL`; `APP_ENV` is already set to `production`.

## 4. Initial test accounts

The seed email addresses and initial passwords are defined in `api.php`, so no seed-password variables are required:

| Role | Email | Initial password |
|---|---|---|
| System Administrator | `admin@jigpoly.edu.ng` | `Admin@1234` |
| Examination Officer | `officer@jigpoly.edu.ng` | `Officer@1234` |
| Invigilator | `invigilator@jigpoly.edu.ng` | `Invigi@1234` |
| HOD / College administrator | `hod@jigpoly.edu.ng` | `Hod@12345` |
| Committee Member | `committee@jigpoly.edu.ng` | `Commit@1234` |

The seed runs only when the `colleges` table is empty. To force a fresh seed in a test database, remove the application tables from Neon and deploy again. Do not do this on a database containing real incidents.

## 5. Local testing with Docker

The same image can be tested locally. Set a local PostgreSQL connection string, then build and run:

```bash
docker build -t jigpoly-oirmf .
docker run --rm -p 8080:80 \
  -e DATABASE_URL="postgresql://USER:PASSWORD@HOST/DB?sslmode=require" \
  -e APP_ENV=production \
  jigpoly-oirmf
```

Open `http://localhost:8080`. Check the health endpoint with:

```bash
curl http://localhost:8080/api.php?action=health
```

A successful response contains `"status":"ok"`.

## Security and operational notes

The application uses prepared statements, bcrypt password hashing, session-bound CSRF tokens, strict session mode, HTTP-only cookies, and server-side role checks. The public API deliberately returns a generic database error instead of exposing SQL details. Keep the seed passwords private, rotate them before sharing the deployment URL, and use HTTPS in production.

The current evidence upload implementation writes temporary files to `uploads/`. Because Render Free storage is not durable, add object storage before relying on evidence retention. Also consider moving schema migration and seed logic into a dedicated deployment step once the application becomes a production system.

## Troubleshooting

If Render reports a database connection error, verify that the Neon URL is copied exactly, includes the correct password, and is stored in Render as `DATABASE_URL` rather than in source code. If the site returns a 500 response, inspect Render logs and confirm that the Docker image built `pdo_pgsql`. If login fails after a partial migration, use a fresh Neon development database and deploy again; do not delete production data as a troubleshooting step.

If the page loads but appears slow on its first visit, the Free Render service may have been sleeping. This is expected behavior on the free compute tier and is separate from the application database connection.

## Change summary

The delivered code changes the database from MySQL to Neon PostgreSQL, replaces all former academic-unit labels with colleges throughout the schema and user interface, standardizes the product branding as JIGPOLY Polytechnic, allows deployment with only `DATABASE_URL` and `APP_ENV`, automatically seeds initial user credentials, adds a Docker deployment path for Render, adds a health endpoint, and prevents raw SQL errors from being returned to users.

You should review the seed names, policies, academic units, and incident workflow with JIGPOLY Polytechnic's authorized administrators before production use.

## References

[1]: https://render.com/docs/free "Render: Deploy for Free"
[2]: https://neon.com/postgresql/php/connect "Neon: Connect to PostgreSQL using PDO"
[3]: https://www.php.net/manual/en/ref.pdo-pgsql.connection.php "PHP Manual: PDO_PGSQL connections"

*Author: Manus AI*
