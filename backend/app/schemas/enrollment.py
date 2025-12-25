"""
Enrollment schemas
"""
from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class EnrollmentCreate(BaseModel):
    user_id: int
    course_id: int
    role: Optional[str] = "student"

class EnrollmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    user_id: int
    course_id: int
    role: str
    created_at: datetime
