"""
Add enrollments table

Run: python -m app.migrations.add_enrollments
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create enrollments table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS enrollments (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
                course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
                role VARCHAR(20) DEFAULT 'student' NOT NULL,
                created_at TIMESTAMP DEFAULT NOW() NOT NULL,
                CONSTRAINT uq_enrollment_user_course UNIQUE (user_id, course_id)
            );
            
            CREATE INDEX IF NOT EXISTS idx_enrollments_user_id ON enrollments(user_id);
            CREATE INDEX IF NOT EXISTS idx_enrollments_course_id ON enrollments(course_id);
        """))
        
        conn.commit()
        print("✓ enrollments table created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS enrollments CASCADE;"))
        conn.commit()
        print("✓ enrollments table dropped")

if __name__ == "__main__":
    print("Running migration: add_enrollments")
    upgrade()
    print("Migration completed!")
