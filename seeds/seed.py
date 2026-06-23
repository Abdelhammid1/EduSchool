"""Seed default school, roles, admin user, and chart of accounts. Idempotent."""
from app import create_app
from app.extensions import db
from app.models import School, Role, User, Account
from app.models.user import PERMISSION_MODULES, PERMISSION_ACTIONS


DEFAULT_ACCOUNTS = [
    # (code, name, type, parent_code, is_system)
    ("1000", "الأصول", "asset", None, True),
    ("1100", "النقدية", "asset", "1000", True),
    ("1200", "البنك", "asset", "1000", True),
    ("1300", "ذمم الطلاب (مدينة)", "asset", "1000", True),
    ("2000", "الخصوم", "liability", None, True),
    ("2100", "ذمم الموردين (دائنة)", "liability", "2000", True),
    ("3000", "حقوق الملكية", "equity", None, True),
    ("3100", "رأس المال", "equity", "3000", True),
    ("4000", "الإيرادات", "revenue", None, True),
    ("4100", "إيرادات رسوم تعليمية", "revenue", "4000", True),
    ("4200", "إيرادات رسوم مواصلات", "revenue", "4000", True),
    ("4900", "إيرادات أخرى", "revenue", "4000", True),
    ("5000", "المصروفات", "expense", None, True),
    ("5100", "رواتب الموظفين", "expense", "5000", True),
    ("5200", "الإيجار والمرافق", "expense", "5000", True),
    ("5300", "الصيانة والمستلزمات", "expense", "5000", True),
    ("5900", "مصروفات أخرى", "expense", "5000", True),
]


DEFAULT_ROLES = [
    ("admin",            "مدير",          True,  "all"),
    ("student_affairs",  "شؤون طلاب",     False, [
        ("students", PERMISSION_ACTIONS), ("sections", ["view"]),
        ("grades", ["view"]), ("academic_years", ["view"]),
    ]),
    ("teacher",          "معلم",          False, [
        ("attendance", PERMISSION_ACTIONS), ("results", ["view", "add", "edit"]),
        ("schedule", ["view"]), ("portal", PERMISSION_ACTIONS),
    ]),
    ("accountant",       "محاسب",         False, [
        ("finance", PERMISSION_ACTIONS), ("expenses", PERMISSION_ACTIONS),
    ]),
    ("warehouse",        "أمين مخزن",     False, [("expenses", ["view", "add"])]),
    ("parent",           "ولي أمر",       False, [("portal", ["view"])]),
]


def all_permissions() -> dict:
    return {m: list(PERMISSION_ACTIONS) for m in PERMISSION_MODULES}


def role_permissions(spec) -> dict:
    if spec == "all":
        return all_permissions()
    return {module: list(actions) for module, actions in spec}


def run():
    app = create_app()
    with app.app_context():
        school = School.query.filter_by(code=app.config["DEFAULT_SCHOOL_CODE"]).first()
        if not school:
            school = School(
                code=app.config["DEFAULT_SCHOOL_CODE"],
                name=app.config["DEFAULT_SCHOOL_NAME"],
            )
            db.session.add(school)
            db.session.commit()
            print(f"✓ Created school: {school.name}")

        for name, name_ar, is_system, spec in DEFAULT_ROLES:
            role = Role.query.filter_by(school_id=school.id, name=name).first()
            if not role:
                role = Role(
                    school_id=school.id,
                    name=name,
                    name_ar=name_ar,
                    is_system=is_system,
                    permissions=role_permissions(spec),
                )
                db.session.add(role)
                print(f"✓ Created role: {name_ar}")
        db.session.commit()

        for code, name, type_, parent_code, is_system in DEFAULT_ACCOUNTS:
            existing = Account.query.filter_by(school_id=school.id, code=code).first()
            if existing:
                continue
            parent = None
            if parent_code:
                parent = Account.query.filter_by(school_id=school.id, code=parent_code).first()
            a = Account(
                school_id=school.id, code=code, name=name, type=type_,
                parent_id=parent.id if parent else None, is_system=is_system,
            )
            db.session.add(a)
            print(f"✓ Created account: {code} {name}")
        db.session.commit()

        admin_role = Role.query.filter_by(school_id=school.id, name="admin").first()
        admin = User.query.filter_by(school_id=school.id, username="admin").first()
        if not admin:
            admin = User(
                school_id=school.id,
                role_id=admin_role.id,
                username="admin",
                full_name="مدير النظام",
                email="admin@manasety.local",
            )
            admin.set_password("admin12345")
            db.session.add(admin)
            db.session.commit()
            print("✓ Created admin user (username=admin / password=admin12345)")
        else:
            print("• Admin user already exists.")

        print("\nDone. Login at /auth/login")


if __name__ == "__main__":
    run()
