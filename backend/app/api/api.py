from fastapi import APIRouter
from app.api.endpoints import auth, categories, courses, files, progress, scanner, backup, config, enrollments, search, notifications, users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
api_router.include_router(files.router, prefix="/files", tags=["files"])
api_router.include_router(progress.router, prefix="/progress", tags=["progress"])
api_router.include_router(enrollments.router, prefix="/enrollments", tags=["enrollments"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(scanner.router, prefix="/scanner", tags=["scanner"])
api_router.include_router(backup.router, prefix="/admin/backup", tags=["backup"])
api_router.include_router(config.router, prefix="/config", tags=["configuration"])
