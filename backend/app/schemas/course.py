from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class CourseBase(BaseModel):
    name: str
    path: str
    category_id: int

class CourseCreate(CourseBase):
    pass

class Course(CourseBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
