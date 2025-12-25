"""
Add search and notifications tables

Run: python -m app.migrations.add_search_notifications
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create announcements table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS announcements (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                content TEXT NOT NULL,
                announcement_type VARCHAR(50) DEFAULT 'course_announcement' NOT NULL,
                course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
                file_id INTEGER REFERENCES file_nodes(id) ON DELETE CASCADE,
                created_by_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
                created_at TIMESTAMP DEFAULT NOW() NOT NULL,
                priority INTEGER DEFAULT 0,
                expires_at TIMESTAMP
            );
            
            CREATE INDEX IF NOT EXISTS idx_announcements_course_id ON announcements(course_id);
            CREATE INDEX IF NOT EXISTS idx_announcements_file_id ON announcements(file_id);
            CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_announcements_type ON announcements(announcement_type);
        """))
        
        # Create user_notifications table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS user_notifications (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
                announcement_id INTEGER REFERENCES announcements(id) ON DELETE CASCADE NOT NULL,
                is_read BOOLEAN DEFAULT FALSE NOT NULL,
                read_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT NOW() NOT NULL,
                UNIQUE(user_id, announcement_id)
            );
            
            CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
            CREATE INDEX IF NOT EXISTS idx_user_notifications_announcement_id ON user_notifications(announcement_id);
            CREATE INDEX IF NOT EXISTS idx_user_notifications_is_read ON user_notifications(is_read);
        """))
        
        # Create search_logs table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS search_logs (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
                query VARCHAR(255) NOT NULL,
                results_count INTEGER DEFAULT 0,
                search_type VARCHAR(50),
                created_at TIMESTAMP DEFAULT NOW() NOT NULL
            );
            
            CREATE INDEX IF NOT EXISTS idx_search_logs_user_id ON search_logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_search_logs_query ON search_logs(query);
            CREATE INDEX IF NOT EXISTS idx_search_logs_created_at ON search_logs(created_at DESC);
        """))
        
        conn.commit()
        print("✓ Search and notification tables created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS search_logs CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS user_notifications CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS announcements CASCADE;"))
        conn.commit()
        print("✓ Search and notification tables dropped")

if __name__ == "__main__":
    print("Running migration: add_search_notifications")
    upgrade()
    print("Migration completed!")
