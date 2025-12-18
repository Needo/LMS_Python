from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class ProgressStatus(str, Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class UserProgressBase(BaseModel):
    user_id: int
    file_id: int
    status: ProgressStatus
    last_position: Optional[int] = None

class UserProgressCreate(UserProgressBase):
    pass

class UserProgress(UserProgressBase):
    id: int
    completed_at: Optional[datetime]
    updated_at: datetime

    class Config:
        from_attributes = True

class LastViewedBase(BaseModel):
    user_id: int
    course_id: int
    file_id: int

class LastViewedCreate(LastViewedBase):
    pass

class LastViewed(LastViewedBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True
