from datetime import datetime
from ..extensions import db


ATTENDANCE_STATUSES = ["present", "absent", "late"]


class Attendance(db.Model):
    __tablename__ = "attendance"

    id = db.Column(db.Integer, primary_key=True)
    school_id = db.Column(db.Integer, db.ForeignKey("schools.id"), nullable=False, index=True)
    enrollment_id = db.Column(db.Integer, db.ForeignKey("enrollments.id"), nullable=False, index=True)
    date = db.Column(db.Date, nullable=False, index=True)
    status = db.Column(db.String(16), nullable=False)
    notes = db.Column(db.String(255))
    recorded_by_user_id = db.Column(db.Integer, db.ForeignKey("users.id"))
    recorded_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    enrollment = db.relationship("Enrollment", backref="attendance_records")

    __table_args__ = (
        db.UniqueConstraint("enrollment_id", "date", name="uq_attendance_enrollment_date"),
    )


class NotificationLog(db.Model):
    __tablename__ = "notification_logs"

    id = db.Column(db.Integer, primary_key=True)
    school_id = db.Column(db.Integer, db.ForeignKey("schools.id"), nullable=False, index=True)
    kind = db.Column(db.String(32), nullable=False)
    target_phone = db.Column(db.String(32))
    target_email = db.Column(db.String(128))
    payload = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(16), default="queued", nullable=False)
    attempts = db.Column(db.Integer, default=0, nullable=False)
    last_attempt_at = db.Column(db.DateTime)
    sent_at = db.Column(db.DateTime)
    error = db.Column(db.String(255))
    related_kind = db.Column(db.String(32))
    related_id = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
