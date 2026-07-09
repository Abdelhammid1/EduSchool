from datetime import datetime, date

from flask import abort, current_app, flash, redirect, render_template, request, url_for
from flask_login import current_user, login_required
from sqlalchemy import func

from . import bp
from ..utils import require_permission
from ...extensions import db
from ...models import (
    AcademicYear, Grade, Section, School, Student, Enrollment, TransferLog, User,
)


def _sid():
    return current_user.school_id


def _active_year():
    return AcademicYear.query.filter_by(school_id=_sid(), status="active").first()


def _next_permanent_code() -> str:
    school = db.session.get(School, _sid())
    n = (
        db.session.query(func.count(Student.id))
        .filter(Student.school_id == _sid())
        .scalar() or 0
    )
    return f"{school.code}-{n + 1:05d}"


def _get(model, oid):
    obj = model.query.filter_by(id=oid, school_id=_sid()).first()
    if not obj:
        abort(404)
    return obj


# ---------- T-3.1: Permanent profile ----------

@bp.route("")
@login_required
@require_permission("students", "view")
def students_list():
    q = (request.args.get("q") or "").strip()
    year = _active_year()
    query = Student.query.filter_by(school_id=_sid())
    if q:
        like = f"%{q}%"
        query = query.filter(
            db.or_(Student.full_name.ilike(like), Student.permanent_code.ilike(like))
        )
    students = query.order_by(Student.full_name).limit(500).all()
    return render_template(
        "students/list.html", students=students, q=q, active_year=year
    )


@bp.route("/new", methods=["GET", "POST"])
@login_required
@require_permission("students", "add")
def student_new():
    if request.method == "POST":
        nid = (request.form.get("national_id") or "").strip() or None
        if nid:
            dup = Student.query.filter_by(school_id=_sid(), national_id=nid).first()
            if dup and request.form.get("confirm_dup") != "1":
                flash(
                    f"تنبيه: يوجد طالب آخر بنفس رقم الهوية ({dup.full_name} — {dup.permanent_code}). "
                    "أكّد الحفظ إذا كنت متأكدًا.",
                    "warning",
                )
                return render_template("students/form.html", student=None, form=request.form, dup=dup, parent_users=_parent_users())

        student = Student(
            school_id=_sid(),
            permanent_code=_next_permanent_code(),
            full_name=request.form["full_name"].strip(),
            national_id=nid,
            dob=_parse_date(request.form.get("dob")),
            gender=request.form.get("gender") or None,
            parent_name=(request.form.get("parent_name") or "").strip() or None,
            parent_phone=(request.form.get("parent_phone") or "").strip() or None,
            parent_email=(request.form.get("parent_email") or "").strip() or None,
            parent_user_id=int(request.form["parent_user_id"]) if request.form.get("parent_user_id") else None,
            mother_name=(request.form.get("mother_name") or "").strip() or None,
            mother_phone=(request.form.get("mother_phone") or "").strip() or None,
            address=(request.form.get("address") or "").strip() or None,
            notes=(request.form.get("notes") or "").strip() or None,
        )
        db.session.add(student)
        db.session.commit()
        flash(f"تم إنشاء ملف الطالب — كود دائم: {student.permanent_code}", "success")
        return redirect(url_for("students.student_detail", student_id=student.id))
    return render_template("students/form.html", student=None, form={}, dup=None, parent_users=_parent_users())


@bp.route("/<int:student_id>")
@login_required
@require_permission("students", "view")
def student_detail(student_id):
    student = _get(Student, student_id)
    year = _active_year()
    has_active_enrollment = any(
        e.year_id == (year.id if year else None) and e.status == "active"
        for e in student.enrollments
    )
    return render_template(
        "students/detail.html",
        student=student,
        active_year=year,
        has_active_enrollment=has_active_enrollment,
    )


@bp.route("/<int:student_id>/edit", methods=["GET", "POST"])
@login_required
@require_permission("students", "edit")
def student_edit(student_id):
    student = _get(Student, student_id)
    if request.method == "POST":
        student.full_name = request.form["full_name"].strip()
        student.national_id = (request.form.get("national_id") or "").strip() or None
        student.dob = _parse_date(request.form.get("dob"))
        student.gender = request.form.get("gender") or None
        student.parent_name = (request.form.get("parent_name") or "").strip() or None
        student.parent_phone = (request.form.get("parent_phone") or "").strip() or None
        student.parent_email = (request.form.get("parent_email") or "").strip() or None
        student.parent_user_id = int(request.form["parent_user_id"]) if request.form.get("parent_user_id") else None
        student.mother_name = (request.form.get("mother_name") or "").strip() or None
        student.mother_phone = (request.form.get("mother_phone") or "").strip() or None
        student.address = (request.form.get("address") or "").strip() or None
        student.notes = (request.form.get("notes") or "").strip() or None
        db.session.commit()
        flash("تم تحديث ملف الطالب.", "success")
        return redirect(url_for("students.student_detail", student_id=student.id))
    return render_template("students/form.html", student=student, form={}, dup=None, parent_users=_parent_users())


def _parent_users():
    return User.query.filter_by(school_id=_sid(), is_active=True).order_by(User.full_name).all()


# ---------- T-3.2: Enroll in active year ----------

@bp.route("/<int:student_id>/enroll", methods=["GET", "POST"])
@login_required
@require_permission("students", "add")
def enroll(student_id):
    student = _get(Student, student_id)
    year = _active_year()
    if not year:
        flash("لا توجد سنة نشطة. أنشئ سنة دراسية أولاً.", "warning")
        return redirect(url_for("academic.years_list"))

    existing = Enrollment.query.filter_by(student_id=student.id, year_id=year.id).first()
    if existing and existing.status == "active":
        flash(f"الطالب مقيّد بالفعل في السنة {year.name}.", "warning")
        return redirect(url_for("students.student_detail", student_id=student.id))

    grades = Grade.query.filter_by(school_id=_sid()).order_by(Grade.order_index).all()
    sections = (
        Section.query.filter_by(school_id=_sid(), year_id=year.id)
        .join(Grade)
        .order_by(Grade.order_index, Section.name)
        .all()
    )

    if request.method == "POST":
        section = _get(Section, int(request.form["section_id"]))
        if section.year_id != year.id:
            abort(400)
        if section.is_full:
            flash(
                f"الفصل ({section.grade.name} / {section.name}) ممتلئ "
                f"({section.current_count}/{section.capacity}). اختر فصلاً آخر.",
                "danger",
            )
            return render_template(
                "students/enroll.html", student=student, year=year, sections=sections, grades=grades
            )

        enrollment = Enrollment(
            school_id=_sid(),
            student_id=student.id,
            year_id=year.id,
            grade_id=section.grade_id,
            section_id=section.id,
            status="active",
            enrolled_at=date.today(),
        )
        db.session.add(enrollment)
        db.session.commit()
        flash(
            f"تم قيد الطالب {student.full_name} في {section.grade.name} / {section.name}.",
            "success",
        )
        return redirect(url_for("students.student_detail", student_id=student.id))

    return render_template(
        "students/enroll.html", student=student, year=year, sections=sections, grades=grades
    )


# ---------- T-3.3: Horizontal transfer ----------

@bp.route("/enrollment/<int:enrollment_id>/transfer", methods=["GET", "POST"])
@login_required
@require_permission("students", "edit")
def transfer(enrollment_id):
    enrollment = _get(Enrollment, enrollment_id)
    if enrollment.status != "active":
        flash("لا يمكن نقل قيد غير نشط.", "danger")
        return redirect(url_for("students.student_detail", student_id=enrollment.student_id))

    siblings = (
        Section.query.filter_by(
            school_id=_sid(), year_id=enrollment.year_id, grade_id=enrollment.grade_id
        )
        .filter(Section.id != enrollment.section_id)
        .order_by(Section.name)
        .all()
    )

    if request.method == "POST":
        to_section = _get(Section, int(request.form["to_section_id"]))
        if to_section.grade_id != enrollment.grade_id or to_section.year_id != enrollment.year_id:
            abort(400)
        if to_section.is_full:
            flash(
                f"الفصل المستهدف ({to_section.name}) ممتلئ "
                f"({to_section.current_count}/{to_section.capacity}). تم منع النقل.",
                "danger",
            )
            return render_template(
                "students/transfer.html", enrollment=enrollment, siblings=siblings
            )

        log = TransferLog(
            school_id=_sid(),
            enrollment_id=enrollment.id,
            from_section_id=enrollment.section_id,
            to_section_id=to_section.id,
            transfer_date=date.today(),
            performed_by_user_id=current_user.id,
            notes=(request.form.get("notes") or "").strip() or None,
        )
        enrollment.section_id = to_section.id
        db.session.add(log)
        db.session.commit()
        flash(
            f"تم نقل الطالب إلى الفصل {to_section.name}. تم توثيق تاريخ النقل.",
            "success",
        )
        return redirect(url_for("students.student_detail", student_id=enrollment.student_id))

    return render_template("students/transfer.html", enrollment=enrollment, siblings=siblings)


# ---------- T-3.5: Status change (withdraw/transfer-out) ----------

@bp.route("/enrollment/<int:enrollment_id>/status", methods=["GET", "POST"])
@login_required
@require_permission("students", "edit")
def status_change(enrollment_id):
    enrollment = _get(Enrollment, enrollment_id)
    if request.method == "POST":
        new_status = request.form["status"]
        if new_status not in {"active", "withdrawn", "transferred"}:
            abort(400)
        enrollment.status = new_status
        enrollment.status_changed_at = date.today()
        enrollment.status_reason = (request.form.get("reason") or "").strip() or None
        db.session.commit()
        flash("تم تحديث حالة قيد الطالب.", "success")
        return redirect(url_for("students.student_detail", student_id=enrollment.student_id))
    return render_template("students/status.html", enrollment=enrollment)


# ---------- T-3.4: Vertical promotion ----------

@bp.route("/promotion", methods=["GET", "POST"])
@login_required
@require_permission("students", "edit")
def promotion():
    years = (
        AcademicYear.query.filter_by(school_id=_sid())
        .order_by(AcademicYear.start_date.desc())
        .all()
    )
    grades = Grade.query.filter_by(school_id=_sid()).order_by(Grade.order_index).all()
    target_year = _active_year()

    from_year_id = request.args.get("from_year_id", type=int)
    grade_id = request.args.get("grade_id", type=int)
    candidates = []
    next_grade = None
    target_sections = []

    if from_year_id and grade_id:
        from_year = _get(AcademicYear, from_year_id)
        current_grade = _get(Grade, grade_id)
        next_grade = (
            Grade.query.filter_by(school_id=_sid())
            .filter(Grade.order_index > current_grade.order_index)
            .order_by(Grade.order_index)
            .first()
        )
        candidates = (
            Enrollment.query.filter_by(
                school_id=_sid(), year_id=from_year.id, grade_id=grade_id, status="active"
            )
            .join(Student)
            .order_by(Student.full_name)
            .all()
        )
        if target_year and next_grade:
            target_sections = (
                Section.query.filter_by(
                    school_id=_sid(), year_id=target_year.id, grade_id=next_grade.id
                )
                .order_by(Section.name)
                .all()
            )

    if request.method == "POST":
        if not target_year:
            flash("لا توجد سنة نشطة لاستقبال الترقية.", "danger")
            return redirect(url_for("students.promotion"))
        action = request.form.get("action")  # promote | retain
        section_id = request.form.get("target_section_id", type=int)
        enrollment_ids = request.form.getlist("enrollment_ids", type=int)
        promoted, retained, skipped = 0, 0, 0

        for eid in enrollment_ids:
            e = Enrollment.query.filter_by(id=eid, school_id=_sid()).first()
            if not e or e.status != "active":
                continue

            already = Enrollment.query.filter_by(
                student_id=e.student_id, year_id=target_year.id
            ).first()
            if already:
                skipped += 1
                continue

            if action == "retain":
                e.final_result = "fail"
                e.status = "promoted_out"
                new_enr = Enrollment(
                    school_id=_sid(),
                    student_id=e.student_id,
                    year_id=target_year.id,
                    grade_id=e.grade_id,
                    section_id=section_id,
                    status="active",
                    enrolled_at=date.today(),
                )
                db.session.add(new_enr)
                retained += 1
            else:
                if not next_grade:
                    skipped += 1
                    continue
                section = db.session.get(Section, section_id) if section_id else None
                if not section or section.grade_id != next_grade.id or section.is_full:
                    skipped += 1
                    continue
                e.final_result = "pass"
                e.status = "promoted_out"
                new_enr = Enrollment(
                    school_id=_sid(),
                    student_id=e.student_id,
                    year_id=target_year.id,
                    grade_id=next_grade.id,
                    section_id=section.id,
                    status="active",
                    enrolled_at=date.today(),
                )
                db.session.add(new_enr)
                promoted += 1
        db.session.commit()
        flash(
            f"تمت الترقية: {promoted} ناجح • {retained} راسب (في نفس الصف) • {skipped} تم تخطيه (سعة/تكرار/قاعدة).",
            "info",
        )
        return redirect(
            url_for("students.promotion", from_year_id=from_year_id, grade_id=grade_id)
        )

    return render_template(
        "students/promotion.html",
        years=years,
        grades=grades,
        from_year_id=from_year_id,
        grade_id=grade_id,
        candidates=candidates,
        next_grade=next_grade,
        target_year=target_year,
        target_sections=target_sections,
    )


# ---------- helpers ----------

def _parse_date(s):
    if not s:
        return None
    return datetime.strptime(s, "%Y-%m-%d").date()
