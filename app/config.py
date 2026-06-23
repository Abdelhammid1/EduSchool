import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-change-me")
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", "postgresql://manasety:manasety@localhost:5432/manasety"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    LOCKOUT_MAX_ATTEMPTS = int(os.environ.get("LOCKOUT_MAX_ATTEMPTS", "5"))
    LOCKOUT_MINUTES = int(os.environ.get("LOCKOUT_MINUTES", "15"))
    DEFAULT_SCHOOL_NAME = os.environ.get("DEFAULT_SCHOOL_NAME", "مدرسة صالح الشريف")
    DEFAULT_SCHOOL_CODE = os.environ.get("DEFAULT_SCHOOL_CODE", "SAS")
    WHATSAPP_PROVIDER = os.environ.get("WHATSAPP_PROVIDER", "stub")
    LANGUAGES = ["ar"]
    DEFAULT_LANGUAGE = "ar"
