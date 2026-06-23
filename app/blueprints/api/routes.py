"""REST API for teacher + parent mobile apps (T-10.2, T-10.3).

All endpoints under /api/ — JWT auth via Authorization: Bearer <token>.
Routes auto-scope to the authenticated user's school_id.
"""
from datetime import datetime, date
from decimal import Decimal

from flask import g, jsonify, request

from . import bp
from ...extensions import csrf, db
from ...models import (
    AcademicYear, Assignment, AssessmentComponent, Attendance, Enrollment,
    GradeEntry, Invoice, Material, NotificationLog, Payment, Section, Student,
    Subject, Teacher, Term, User, YearResult,
)
from ...models.results import RESULT_STATUSES
from ...services.auth_jwt import issue_token, jwt_required
from ...services.notifications import send_notification

# CSRF exempt entire API (uses JWT instead of session cookies)
csrf.exempt(bp)


def _err(msg, code=400):
    return jsonify({"error": msg}), code


def _user():
    return g.api_user


def _sid():
    return _user().school_id


def _active_year():
    return AcademicYear.query.filter_by(school_id=_sid(), status="active").first()


def _teacher_for(user):
    return Teacher.query.filter_by(school_id=user.school_id, user_id=user.id).first()


# ---------- Auth ----------

@bp.route("/auth/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""
    if not username or not password:
        return _err("missing credentials")
    user = User.query.filter_by(username=username).first()
    if not user or not user.is_active or not user.check_password(password):
        return _err("invalid credentials", 401)

    user.last_login_at = datetime.utcnow()
    db.session.commit()
    return jsonify({
        "token": issue_token(user),
        "user": _user_dict(user),
    })


@bp.route("/me", methods=["GET"])
@jwt_required
def me():
    return jsonify({"user": _user_dict(_user())})


def _user_dict(user: User) -> dict:
    teacher = Teacher.query.filter_by(user_id=user.id).first()
    children_count = Student.query.filter_by(parent_user_id=user.id).count()
    return {
        "id": user.id,
        "username": user.username,
        "full_name": user.full_name,
        "role": user.role.name if user.role else None,
        "role_ar": user.role.name_ar if user.role else None,
        "is_teacher": bool(teacher),
        "teacher_id": teacher.id if teacher else None,
        "children_count": children_count,
    }


# ============================================================
# Teacher endpoints
# ============================================================

@bp.route("/teacher/schedule", methods=["GET"])
@jwt_required
def teacher_schedule():
    t = _teacher_for(_user())
    if not t:
        return _err("not a teacher", 403)
    year = _active_year()
    if not year:
        return jsonify({"slots": []})
    from ...models import ScheduleSlot
    slots = ScheduleSlot.query.filter_by(
        school_id=_sid(), year_id=year.id, teacher_id=t.id,
    ).all()
    return jsonify({
        "slots": [
            {
                "day_id": s.day_id, "day_name": s.day.name,
                "period_id": s.period_id, "period_name": s.period.name,
                "start_time": s.period.start_time.strftime("%H:%M"),
                "end_time": s.period.end_time.strftime("%H:%M"),
                "section_id": s.section_id,
                "section_name": f"{s.section.grade.name} / {s.section.name}",
                "subject_id": s.subject_id,
                "subject_name": s.subject.name,
            } for s in slots
        ]
    })


@bp.route("/teacher/sections", methods=["GET"])
@jwt_required
def teacher_sections():
    t = _teacher_for(_user())
    if not t:
        return _err("not a teacher", 403)
    year = _active_year()
    if not year:
        return jsonify({"sections": []})
    assignments = Assignment.query.filter_by(
        teacher_id=t.id, year_id=year.id, is_active=True
    ).all()
    seen = {}
    for a in assignments:
        if a.section_id not in seen:
            seen[a.section_id] = {
                "id": a.section.id,
                "name": f"{a.section.grade.name} / {a.section.name}",
                "subjects": [],
            }
        seen[a.section_id]["subjects"].append({"id": a.subject.id, "name": a.subject.name})
    return jsonify({"sections": list(seen.values())})


@bp.route("/teacher/students", methods=["GET"])
@jwt_required
def teacher_students():
    section_id = request.args.get("section_id", type=int)
    if not section_id:
        return _err("section_id required")
    section = Section.query.filter_by(id=section_id, school_id=_sid()).first()
    if not section:
        return _err("section not found", 404)
    enrollments = (
        Enrollment.query.filter_by(
            school_id=_sid(), year_id=section.year_id, section_id=section.id, status="active"
        ).join(Student).order_by(Student.full_name).all()
    )
    return jsonify({"students": [
        {
            "enrollment_id": e.id,
            "student_id": e.student.id,
            "permanent_code": e.student.permanent_code,
            "full_name": e.student.full_name,
        } for e in enrollments
    ]})


@bp.route("/teacher/attendance", methods=["POST"])
@jwt_required
def teacher_attendance():
    """Body: {section_id, date, records: [{enrollment_id, status, notes?}]}"""
    t = _teacher_for(_user())
    if not t:
        return _err("not a teacher", 403)
    data = request.get_json(silent=True) or {}
    section_id = data.get("section_id")
    on_date = _parse_date(data.get("date")) or date.today()
    records = data.get("records") or []
    if not section_id or not records:
        return _err("missing section_id or records")

    section = Section.query.filter_by(id=section_id, school_id=_sid()).first()
    if not section:
        return _err("section not found", 404)

    # Ensure teacher is assigned to this section
    if not Assignment.query.filter_by(
        teacher_id=t.id, section_id=section.id, year_id=section.year_id, is_active=True
    ).first():
        return _err("teacher not assigned to this section", 403)

    creates = updates = absent_notifs = 0
    valid_ids = {e.id for e in Enrollment.query.filter_by(
        school_id=_sid(), year_id=section.year_id, section_id=section.id, status="active"
    ).all()}

    for r in records:
        eid = r.get("enrollment_id")
        status = r.get("status")
        if eid not in valid_ids or status not in ("present", "absent", "late"):
            continue
        existing = Attendance.query.filter_by(enrollment_id=eid, date=on_date).first()
        prev = existing.status if existing else None
        if existing:
            existing.status = status
            existing.notes = r.get("notes")
            existing.recorded_by_user_id = _user().id
            existing.recorded_at = datetime.utcnow()
            updates += 1
        else:
            existing = Attendance(
                school_id=_sid(), enrollment_id=eid, date=on_date,
                status=status, notes=r.get("notes"),
                recorded_by_user_id=_user().id,
            )
            db.session.add(existing)
            creates += 1
        db.session.flush()
        if status == "absent" and prev != "absent":
            e = Enrollment.query.get(eid)
            phone = (e.student.parent_phone or "").strip()
            if phone:
                send_notification(
                    school_id=_sid(), kind="absence",
                    payload={
                        "student": e.student.full_name,
                        "date": on_date.isoformat(),
                        "message": f"غياب: {e.student.full_name} بتاريخ {on_date.isoformat()}",
                    },
                    target_phone=phone,
                    related_kind="attendance", related_id=existing.id,
                )
                absent_notifs += 1
    db.session.commit()
    return jsonify({
        "creates": creates, "updates": updates, "absent_notifications": absent_notifs,
    })


@bp.route("/teacher/grades", methods=["POST"])
@jwt_required
def teacher_grades():
    """Body: {section_id, term_id, subject_id, entries: [{enrollment_id, component_id, score}]}"""
    t = _teacher_for(_user())
    if not t:
        return _err("not a teacher", 403)
    data = request.get_json(silent=True) or {}
    section_id = data.get("section_id")
    term_id = data.get("term_id")
    subject_id = data.get("subject_id")
    entries = data.get("entries") or []
    if not (section_id and term_id and subject_id and entries):
        return _err("missing fields")

    section = Section.query.filter_by(id=section_id, school_id=_sid()).first()
    if not section:
        return _err("section not found", 404)
    if not Assignment.query.filter_by(
        teacher_id=t.id, section_id=section.id, subject_id=subject_id,
        year_id=section.year_id, is_active=True
    ).first():
        return _err("teacher not assigned to this subject in this section", 403)

    if YearResult.query.join(Enrollment).filter(
        Enrollment.section_id == section.id, Enrollment.year_id == section.year_id
    ).first():
        return _err("results approved; grades locked", 403)

    saved = rejected = 0
    valid_eids = {e.id for e in Enrollment.query.filter_by(
        school_id=_sid(), year_id=section.year_id, section_id=section.id, status="active"
    ).all()}
    comps = {c.id: c for c in AssessmentComponent.query.filter_by(
        school_id=_sid(), term_id=term_id, subject_id=subject_id
    ).all()}

    for e in entries:
        eid = e.get("enrollment_id")
        cid = e.get("component_id")
        raw = e.get("score")
        if eid not in valid_eids or cid not in comps:
            rejected += 1; continue
        try:
            score = Decimal(str(raw))
        except Exception:  # noqa: BLE001
            rejected += 1; continue
        if score < 0 or score > comps[cid].max_score:
            rejected += 1; continue
        ge = GradeEntry.query.filter_by(enrollment_id=eid, component_id=cid).first()
        if ge:
            ge.score = score
            ge.recorded_by_user_id = _user().id
            ge.recorded_at = datetime.utcnow()
        else:
            ge = GradeEntry(
                school_id=_sid(), enrollment_id=eid, component_id=cid,
                score=score, recorded_by_user_id=_user().id,
            )
            db.session.add(ge)
        saved += 1
    db.session.commit()
    return jsonify({"saved": saved, "rejected": rejected})


@bp.route("/teacher/materials", methods=["GET", "POST"])
@jwt_required
def teacher_materials():
    t = _teacher_for(_user())
    if not t:
        return _err("not a teacher", 403)

    if request.method == "POST":
        data = request.get_json(silent=True) or {}
        section_id = data.get("section_id")
        subject_id = data.get("subject_id")
        title = (data.get("title") or "").strip()
        kind = data.get("kind") or "link"
        url = (data.get("external_url") or "").strip() or None
        desc = (data.get("description") or "").strip() or None
        if not (section_id and subject_id and title):
            return _err("missing fields")
        section = Section.query.filter_by(id=section_id, school_id=_sid()).first()
        if not section:
            return _err("section not found", 404)
        if kind not in ("file", "video", "link"):
            return _err("invalid kind")
        m = Material(
            school_id=_sid(), teacher_id=t.id, year_id=section.year_id,
            section_id=section.id, subject_id=subject_id, title=title,
            description=desc, kind=kind, external_url=url,
        )
        db.session.add(m)
        db.session.commit()
        return jsonify({"id": m.id, "title": m.title}), 201

    materials = Material.query.filter_by(school_id=_sid(), teacher_id=t.id).order_by(Material.created_at.desc()).all()
    return jsonify({"materials": [_material_dict(m) for m in materials]})


def _material_dict(m):
    return {
        "id": m.id, "title": m.title, "description": m.description,
        "kind": m.kind, "external_url": m.external_url, "file_path": m.file_path,
        "section_name": f"{m.section.grade.name} / {m.section.name}",
        "subject_name": m.subject.name,
        "created_at": m.created_at.isoformat(),
    }


# ============================================================
# Parent endpoints
# ============================================================

@bp.route("/parent/children", methods=["GET"])
@jwt_required
def parent_children():
    children = Student.query.filter_by(school_id=_sid(), parent_user_id=_user().id).all()
    out = []
    year = _active_year()
    for s in children:
        enr = None
        if year:
            enr = next((e for e in s.enrollments if e.year_id == year.id and e.status == "active"), None)
        out.append({
            "id": s.id, "permanent_code": s.permanent_code, "full_name": s.full_name,
            "current_section": (
                f"{enr.grade.name} / {enr.section.name}" if enr else None
            ),
            "current_year": year.name if year else None,
        })
    return jsonify({"children": out})


def _check_child(student_id):
    s = Student.query.filter_by(id=student_id, school_id=_sid(), parent_user_id=_user().id).first()
    return s


@bp.route("/parent/child/<int:student_id>/attendance", methods=["GET"])
@jwt_required
def parent_child_attendance(student_id):
    s = _check_child(student_id)
    if not s:
        return _err("child not found", 404)
    eids = [e.id for e in s.enrollments if e.status == "active"]
    records = (
        Attendance.query.filter(Attendance.enrollment_id.in_(eids))
        .order_by(Attendance.date.desc()).limit(60).all()
    )
    p = sum(1 for r in records if r.status == "present")
    a = sum(1 for r in records if r.status == "absent")
    l = sum(1 for r in records if r.status == "late")
    total = p + a + l
    return jsonify({
        "summary": {"present": p, "absent": a, "late": l, "total": total,
                    "rate": round((p / total * 100) if total else 0, 1)},
        "records": [
            {"date": r.date.isoformat(), "status": r.status, "notes": r.notes}
            for r in records
        ],
    })


@bp.route("/parent/child/<int:student_id>/results", methods=["GET"])
@jwt_required
def parent_child_results(student_id):
    s = _check_child(student_id)
    if not s:
        return _err("child not found", 404)
    # Only APPROVED results (T-10.3 acceptance)
    out = []
    for enr in s.enrollments:
        yr = YearResult.query.filter_by(enrollment_id=enr.id).first()
        if not yr:
            continue
        out.append({
            "year": enr.year.name,
            "grade": enr.grade.name,
            "section": enr.section.name,
            "status": yr.status,
            "average": float(yr.average),
            "subject_scores": yr.subject_scores,
            "approved_at": yr.approved_at.isoformat(),
        })
    return jsonify({"results": out})


@bp.route("/parent/child/<int:student_id>/invoices", methods=["GET"])
@jwt_required
def parent_child_invoices(student_id):
    s = _check_child(student_id)
    if not s:
        return _err("child not found", 404)
    eids = [e.id for e in s.enrollments]
    invoices = Invoice.query.filter(Invoice.enrollment_id.in_(eids)).order_by(Invoice.issue_date.desc()).all()
    return jsonify({"invoices": [
        {
            "id": i.id, "number": i.number,
            "issue_date": i.issue_date.isoformat(),
            "due_date": i.due_date.isoformat(),
            "total_amount": float(i.total_amount),
            "paid_amount": float(i.paid_amount),
            "remaining": float(i.remaining),
            "status": i.status,
        } for i in invoices
    ]})


@bp.route("/parent/notifications", methods=["GET"])
@jwt_required
def parent_notifications():
    children = Student.query.filter_by(school_id=_sid(), parent_user_id=_user().id).all()
    phones = {(s.parent_phone or "").strip() for s in children if s.parent_phone}
    if not phones:
        return jsonify({"notifications": []})
    notifs = (
        NotificationLog.query.filter(
            NotificationLog.school_id == _sid(),
            NotificationLog.target_phone.in_(list(phones)),
        )
        .order_by(NotificationLog.created_at.desc()).limit(50).all()
    )
    return jsonify({"notifications": [
        {
            "id": n.id, "kind": n.kind, "status": n.status,
            "payload": n.payload, "created_at": n.created_at.isoformat(),
        } for n in notifs
    ]})


@bp.route("/parent/child/<int:student_id>/materials", methods=["GET"])
@jwt_required
def parent_child_materials(student_id):
    s = _check_child(student_id)
    if not s:
        return _err("child not found", 404)
    year = _active_year()
    if not year:
        return jsonify({"materials": []})
    enr = next((e for e in s.enrollments if e.year_id == year.id and e.status == "active"), None)
    if not enr:
        return jsonify({"materials": []})
    materials = Material.query.filter_by(
        school_id=_sid(), section_id=enr.section_id, year_id=year.id
    ).order_by(Material.created_at.desc()).all()
    return jsonify({"materials": [_material_dict(m) for m in materials]})


def _parse_date(s):
    if not s:
        return None
    try:
        return datetime.strptime(s, "%Y-%m-%d").date()
    except (ValueError, TypeError):
        return None
