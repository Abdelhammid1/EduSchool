from flask import render_template
from flask_login import current_user, login_required

from . import bp
from ...models import (
    AcademicYear, Enrollment, Grade, Section, Student, Subject, Teacher, User,
)


@bp.route("/dashboard")
@login_required
def home():
    sid = current_user.school_id
    active_year = AcademicYear.query.filter_by(school_id=sid, status="active").first()
    students_total = Student.query.filter_by(school_id=sid).count()
    students_active = 0
    if active_year:
        students_active = Enrollment.query.filter_by(
            school_id=sid, year_id=active_year.id, status="active"
        ).count()
    stats = {
        "users": User.query.filter_by(school_id=sid, is_active=True).count(),
        "grades": Grade.query.filter_by(school_id=sid).count(),
        "sections": Section.query.filter_by(school_id=sid).count(),
        "active_year": active_year.name if active_year else "—",
        "students_total": students_total,
        "students_active": students_active,
        "teachers": Teacher.query.filter_by(school_id=sid, is_active=True).count(),
        "subjects": Subject.query.filter_by(school_id=sid).count(),
    }
    return render_template("dashboard/home.html", stats=stats)
