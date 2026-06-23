# EduSchool / منصتي (Manasety)

نظام إدارة مدرسية متكامل — School ERP + SIS + Educational Portal

## Stack
Flask 3 · PostgreSQL · SQLAlchemy · Flask-Migrate · Flask-Login · Bcrypt · Flask-WTF (CSRF) · Jinja2 (RTL)

## Completed Sprints (5 of 6)

| # | Module | Tasks | Status |
|---|---|---|---|
| 1 | Foundation — users/roles/perms + academic structure | T-1.1→1.3, T-2.1→2.4 | ✅ |
| 2 | Students — permanent profile, enrollment, transfers, promotion | T-3.1→3.5 | ✅ |
| 3 | Teachers & Schedules — assignments, time grid, conflict prevention | T-4.1→4.3, T-5.1→5.4 | ✅ |
| 4 | Attendance & Results — daily marking, WhatsApp Integration Point, flexible pass rule | T-6.1→6.3, T-7.1→7.6 | ✅ |
| 5 | Finance ERP + HR — chart of accounts, double-entry journal, invoices, payroll | T-8.1→8.5, T-9.1→9.3 | ✅ |
| 6 | Teacher portal + Mobile apps (Flask REST + Flutter) | T-10.1→10.3 | Pending |

## Deployment

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for the full Arabic guide:
- Hetzner Cloud server setup (Ubuntu + nginx + gunicorn + systemd + Let's Encrypt)
- PostgreSQL provisioning
- Initial admin seed
- Admin onboarding walkthrough (year → terms → grades → sections → teachers → students → operations)
- Daily backups + maintenance

## Local quick start

```bash
createdb manasety
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # edit DATABASE_URL if needed
flask --app flask_app db upgrade
python -m seeds.seed
python flask_app.py
```

Login: `admin` / `admin12345` at http://localhost:5050.

## Architecture highlights

- **Multi-tenant from day 1**: `school_id` FK on every table
- **Annual binding**: student data permanent, year-specific data (enrollment, grades, fees) per-year
- **Double-entry accounting**: `services/accounting.py` enforces DR=CR atomically on every financial operation
- **Configurable everywhere**: roles, fee types, accounts, assessment components, pass rules — all editable from UI
- **Integration Point**: WhatsApp notifications abstracted in `services/notifications.py`, swappable provider
- **Approval freeze**: year results snapshot `rule_snapshot` + `subject_scores` JSON for archival immutability

## Repo
https://github.com/Abdelhammid1/EduSchool
