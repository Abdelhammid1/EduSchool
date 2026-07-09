from datetime import datetime
from decimal import Decimal

from flask import abort, flash, redirect, render_template, request, url_for
from flask_login import current_user, login_required
from sqlalchemy import func

from . import bp
from ..utils import require_permission
from ...extensions import db
from ...models import AcademicYear, Grade, Section, Term


def _sid():
    return current_user.school_id


# ---------- Academic Years (T-2.1) ----------

@bp.route("/years")
@login_required
@require_permission("academic_years", "view")
def years_list():
    years = (
        AcademicYear.query.filter_by(school_id=_sid())
        .order_by(AcademicYear.start_date.desc())
        .all()
    )
    return render_template("academic/years_list.html", years=years)


@bp.route("/years/new", methods=["GET", "POST"])
@login_required
@require_permission("academic_years", "add")
def year_new():
    if request.method == "POST":
        status = request.form.get("status", "active")
        if status == "active":
            existing = AcademicYear.query.filter_by(school_id=_sid(), status="active").first()
            if existing:
                flash(
                    f"يوجد سنة نشطة ({existing.name}). أغلقها أولاً قبل تفعيل سنة جديدة.",
                    "warning",
                )
                return render_template("academic/year_form.html", year=None)

        year = AcademicYear(
            school_id=_sid(),
            name=request.form["name"].strip(),
            start_date=datetime.strptime(request.form["start_date"], "%Y-%m-%d").date(),
            end_date=datetime.strptime(request.form["end_date"], "%Y-%m-%d").date(),
            status=status,
        )
        db.session.add(year)
        db.session.commit()
        flash("تم إنشاء السنة الدراسية.", "success")
        return redirect(url_for("academic.years_list"))
    return render_template("academic/year_form.html", year=None)


@bp.route("/years/<int:year_id>/close", methods=["POST"])
@login_required
@require_permission("academic_years", "edit")
def year_close(year_id):
    year = _get(AcademicYear, year_id)
    year.status = "closed"
    db.session.commit()
    flash("تم إغلاق السنة (أرشيف). لا يمكن تعديل بياناتها التشغيلية.", "info")
    return redirect(url_for("academic.years_list"))


# ---------- Terms (T-2.2) ----------

@bp.route("/years/<int:year_id>/terms")
@login_required
@require_permission("terms", "view")
def terms_list(year_id):
    year = _get(AcademicYear, year_id)
    total = sum((t.weight or Decimal(0)) for t in year.terms)
    return render_template("academic/terms_list.html", year=year, total_weight=total)


@bp.route("/years/<int:year_id>/terms/new", methods=["GET", "POST"])
@login_required
@require_permission("terms", "add")
def term_new(year_id):
    year = _get(AcademicYear, year_id)
    if year.status == "closed":
        flash("السنة مغلقة، لا يمكن تعديل الفترات الدراسية.", "danger")
        return redirect(url_for("academic.terms_list", year_id=year_id))
    if request.method == "POST":
        term = Term(
            school_id=_sid(),
            year_id=year.id,
            name=request.form["name"].strip(),
            order_index=int(request.form["order_index"]),
            start_date=datetime.strptime(request.form["start_date"], "%Y-%m-%d").date(),
            end_date=datetime.strptime(request.form["end_date"], "%Y-%m-%d").date(),
            weight=Decimal(request.form["weight"]),
        )
        db.session.add(term)
        db.session.commit()

        total = db.session.query(func.coalesce(func.sum(Term.weight), 0)).filter_by(year_id=year.id).scalar()
        if Decimal(total) != Decimal(100):
            flash(f"تنبيه: مجموع أوزان الفترات الدراسية = {total}% (يفترض 100%).", "warning")
        else:
            flash("تم إضافة الفترة الدراسية. مجموع الأوزان = 100%.", "success")
        return redirect(url_for("academic.terms_list", year_id=year.id))
    return render_template("academic/term_form.html", year=year, term=None)


@bp.route("/terms/<int:term_id>/delete", methods=["POST"])
@login_required
@require_permission("terms", "delete")
def term_delete(term_id):
    term = _get(Term, term_id)
    year_id = term.year_id
    db.session.delete(term)
    db.session.commit()
    flash("تم حذف الفترة الدراسية.", "success")
    return redirect(url_for("academic.terms_list", year_id=year_id))


# ---------- Grades (T-2.3) ----------

@bp.route("/grades")
@login_required
@require_permission("grades", "view")
def grades_list():
    grades = (
        Grade.query.filter_by(school_id=_sid())
        .order_by(Grade.order_index)
        .all()
    )
    return render_template("academic/grades_list.html", grades=grades)


@bp.route("/grades/new", methods=["GET", "POST"])
@login_required
@require_permission("grades", "add")
def grade_new():
    if request.method == "POST":
        grade = Grade(
            school_id=_sid(),
            name=request.form["name"].strip(),
            order_index=int(request.form["order_index"]),
            stage=request.form.get("stage") or None,
        )
        db.session.add(grade)
        db.session.commit()
        flash("تم إضافة الصف.", "success")
        return redirect(url_for("academic.grades_list"))
    return render_template("academic/grade_form.html", grade=None)


@bp.route("/grades/<int:grade_id>/edit", methods=["GET", "POST"])
@login_required
@require_permission("grades", "edit")
def grade_edit(grade_id):
    grade = _get(Grade, grade_id)
    if request.method == "POST":
        grade.name = request.form["name"].strip()
        grade.order_index = int(request.form["order_index"])
        grade.stage = request.form.get("stage") or None
        db.session.commit()
        flash("تم تحديث الصف.", "success")
        return redirect(url_for("academic.grades_list"))
    return render_template("academic/grade_form.html", grade=grade)


# ---------- Sections (T-2.4) ----------

@bp.route("/sections")
@login_required
@require_permission("sections", "view")
def sections_list():
    year = AcademicYear.query.filter_by(school_id=_sid(), status="active").first()
    sections = []
    if year:
        sections = (
            Section.query.filter_by(school_id=_sid(), year_id=year.id)
            .join(Grade)
            .order_by(Grade.order_index, Section.name)
            .all()
        )
    return render_template("academic/sections_list.html", sections=sections, active_year=year)


@bp.route("/sections/new", methods=["GET", "POST"])
@login_required
@require_permission("sections", "add")
def section_new():
    year = AcademicYear.query.filter_by(school_id=_sid(), status="active").first()
    if not year:
        flash("يجب إنشاء سنة دراسية نشطة أولاً.", "warning")
        return redirect(url_for("academic.years_list"))
    grades = Grade.query.filter_by(school_id=_sid()).order_by(Grade.order_index).all()
    if request.method == "POST":
        section = Section(
            school_id=_sid(),
            year_id=year.id,
            grade_id=int(request.form["grade_id"]),
            name=request.form["name"].strip(),
            capacity=int(request.form.get("capacity") or 30),
        )
        db.session.add(section)
        db.session.commit()
        flash("تم إضافة الفصل.", "success")
        return redirect(url_for("academic.sections_list"))
    return render_template("academic/section_form.html", section=None, grades=grades, year=year)


# ---------- helpers ----------

def _get(model, oid):
    obj = model.query.filter_by(id=oid, school_id=_sid()).first()
    if not obj:
        abort(404)
    return obj
