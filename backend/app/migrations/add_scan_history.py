"""
Add scan_history, scan_errors, and scan_lock tables

Run: python -m app.migrations.add_scan_history
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create scan_history table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS scan_history (
                id SERIAL PRIMARY KEY,
                started_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                started_at TIMESTAMP DEFAULT NOW() NOT NULL,
                completed_at TIMESTAMP,
                status VARCHAR(20) DEFAULT 'pending' NOT NULL,
                root_path VARCHAR(500) NOT NULL,
                categories_found INTEGER DEFAULT 0,
                courses_found INTEGER DEFAULT 0,
                files_added INTEGER DEFAULT 0,
                files_updated INTEGER DEFAULT 0,
                files_removed INTEGER DEFAULT 0,
                errors_count INTEGER DEFAULT 0,
                message TEXT,
                error_message TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_scan_history_status ON scan_history(status);
            CREATE INDEX IF NOT EXISTS idx_scan_history_started_at ON scan_history(started_at);
            CREATE INDEX IF NOT EXISTS idx_scan_history_started_by ON scan_history(started_by_id);
        """))
        
        # Create scan_errors table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS scan_errors (
                id SERIAL PRIMARY KEY,
                scan_id INTEGER REFERENCES scan_history(id) ON DELETE CASCADE,
                file_path VARCHAR(500) NOT NULL,
                error_type VARCHAR(100) NOT NULL,
                error_message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            );
            
            CREATE INDEX IF NOT EXISTS idx_scan_errors_scan_id ON scan_errors(scan_id);
            CREATE INDEX IF NOT EXISTS idx_scan_errors_error_type ON scan_errors(error_type);
        """))
        
        # Create scan_lock table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS scan_lock (
                id INTEGER PRIMARY KEY DEFAULT 1,
                is_locked BOOLEAN DEFAULT FALSE NOT NULL,
                locked_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                locked_at TIMESTAMP,
                scan_id INTEGER REFERENCES scan_history(id) ON DELETE SET NULL,
                CONSTRAINT single_lock CHECK (id = 1)
            );
            
            -- Insert single lock row
            INSERT INTO scan_lock (id, is_locked) VALUES (1, FALSE)
            ON CONFLICT (id) DO NOTHING;
        """))
        
        conn.commit()
        print("✓ scan_history, scan_errors, and scan_lock tables created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS scan_errors CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS scan_lock CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS scan_history CASCADE;"))
        conn.commit()
        print("✓ Tables dropped")

if __name__ == "__main__":
    print("Running migration: add_scan_history")
    upgrade()
    print("Migration completed!")
