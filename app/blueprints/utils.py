from functools import wraps
from flask import abort
from flask_login import current_user


def require_permission(module: str, action: str = "view"):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if not current_user.is_authenticated:
                abort(401)
            if not current_user.can(module, action):
                abort(403)
            return view(*args, **kwargs)
        return wrapped
    return decorator
