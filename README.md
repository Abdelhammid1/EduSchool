# منصتي (Manasety) — School Management System

نظام إدارة مدرسية متكامل لمدرسة صالح الشريف (المرحلة الأولى — الأساس).

## Stack
Flask 3 · PostgreSQL · SQLAlchemy · Flask-Migrate · Flask-Login · Bcrypt · Jinja2 (RTL)

## Quick start

```bash
# 1. Postgres database
createdb -U postgres manasety
psql -U postgres -c "CREATE USER manasety WITH PASSWORD 'manasety';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE manasety TO manasety;"

# 2. Python env
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Config
cp .env.example .env

# 4. Migrate + seed
flask db init        # first time only
flask db migrate -m "init"
flask db upgrade
python -m seeds.seed

# 5. Run (kill anything on :5000 first)
lsof -ti:5000 | xargs kill -9 2>/dev/null
python flask_app.py
```

Open http://localhost:5000 — login `admin` / `admin12345`.

## Sprint 1 scope (this commit)
- **§1 Foundation**: T-1.1 secure login + lockout · T-1.2 roles & permissions matrix · T-1.3 user management
- **§2 Academic structure**: T-2.1 academic years (single-active rule) · T-2.2 terms with weights · T-2.3 grades · T-2.4 sections

## Coming next (per the Backlog PDF)
S2 Students · S3 Teachers + Schedules · S4 Attendance + Results · S5 Finance (ERP) · S6 Portals + Mobile apps
