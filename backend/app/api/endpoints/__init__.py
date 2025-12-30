"""
API endpoints package
"""
from . import auth
from . import categories
from . import courses
from . import files
from . import progress
from . import scanner
from . import backup
from . import config
from . import enrollments
from . import search
from . import notifications
from . import users

__all__ = [
    'auth',
    'categories',
    'courses',
    'files',
    'progress',
    'scanner',
    'backup',
    'config',
    'enrollments',
    'search',
    'notifications',
    'users'
]
