"""Seed / reset the App Store Review demo parent account.

Run this ONCE on the production server whenever Apple's review team
needs a working parent login. It is idempotent — safe to re-run.

    cd /path/to/schoolsudan
    source .venv/bin/activate       # or however you activate on prod
    python scripts/create_apple_reviewer.py

Prints the credentials at the end. Copy them into
App Store Connect → App → App Information → Sign-In Information.
"""
from __future__ import annotations

import sys

from app import create_app
from app.extensions import db
from app.models import Role, School, Student, User


REVIEWER_USERNAME = "apple_reviewer"
REVIEWER_PASSWORD = "AppReview2026!"
REVIEWER_FULL_NAME = "Apple App Store Reviewer"
REVIEWER_EMAIL = "apple-review@manasety.ai"


def _find_or_die(school: School) -> tuple[Role, Student]:
    # Any role with the word 'parent' — schools may localise the name.
    parent_role = (
        Role.query.filter_by(school_id=school.id)
        .filter(db.or_(Role.name.ilike("%parent%"), Role.name_ar.ilike("%أمر%")))
        .first()
    )
    if not parent_role:
        sys.exit(
            "❌ Could not find a Parent role in the DB. Create one from the "
            "admin UI first, then rerun this script."
        )

    student = (
        Student.query.filter_by(school_id=school.id)
        .order_by(Student.id.asc())
        .first()
    )
    if not student:
        sys.exit(
            "❌ No students in the DB — the reviewer must have at least one "
            "child to see the app's main features. Add a student first."
        )

    return parent_role, student


def main() -> None:
    app = create_app()
    with app.app_context():
        school = School.query.order_by(School.id.asc()).first()
        if not school:
            sys.exit("❌ No school records found — nothing to attach the reviewer to.")

        parent_role, first_student = _find_or_die(school)

        user = User.query.filter_by(
            school_id=school.id, username=REVIEWER_USERNAME
        ).first()
        if user:
            print(f"↻ Existing reviewer user found (id={user.id}) — resetting password.")
        else:
            user = User(
                school_id=school.id,
                role_id=parent_role.id,
                username=REVIEWER_USERNAME,
                full_name=REVIEWER_FULL_NAME,
                email=REVIEWER_EMAIL,
            )
            db.session.add(user)
            print(f"＋ Creating new reviewer user in school '{school.name_ar or school.name}'.")

        user.role_id = parent_role.id
        user.is_active = True
        user.failed_attempts = 0
        user.locked_until = None
        user.set_password(REVIEWER_PASSWORD)

        db.session.flush()  # get user.id if new

        if first_student.parent_user_id != user.id:
            first_student.parent_user_id = user.id
            print(
                f"🔗 Linked reviewer to student '{first_student.full_name}' "
                f"(id={first_student.id})."
            )
        else:
            print(f"✓ Reviewer already linked to student id={first_student.id}.")

        db.session.commit()

        print("\n" + "=" * 60)
        print("✅ Apple Reviewer account is ready. Paste into App Store Connect:")
        print("=" * 60)
        print(f"  Username : {REVIEWER_USERNAME}")
        print(f"  Password : {REVIEWER_PASSWORD}")
        print(f"  Linked to: {first_student.full_name} (student id={first_student.id})")
        print("=" * 60)


if __name__ == "__main__":
    main()
