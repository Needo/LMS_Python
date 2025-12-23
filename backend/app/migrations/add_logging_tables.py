"""
Add scan_logs and file_access_logs tables

Run: python -m app.migrations.add_logging_tables
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create scan_logs table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS scan_logs (
                id SERIAL PRIMARY KEY,
                scan_id INTEGER REFERENCES scan_history(id) ON DELETE CASCADE NOT NULL,
                correlation_id VARCHAR(36),
                timestamp TIMESTAMP DEFAULT NOW() NOT NULL,
                level VARCHAR(20) DEFAULT 'info' NOT NULL,
                message TEXT NOT NULL,
                module VARCHAR(100),
                function VARCHAR(100),
                file_path VARCHAR(500),
                category VARCHAR(200),
                course VARCHAR(200),
                extra TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_scan_logs_scan_id ON scan_logs(scan_id);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_correlation_id ON scan_logs(correlation_id);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_timestamp ON scan_logs(timestamp);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_level ON scan_logs(level);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_file_path ON scan_logs(file_path);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_scan_timestamp ON scan_logs(scan_id, timestamp);
            CREATE INDEX IF NOT EXISTS idx_scan_logs_level_timestamp ON scan_logs(level, timestamp);
        """))
        
        # Create file_access_logs table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS file_access_logs (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                file_id INTEGER REFERENCES file_nodes(id) ON DELETE SET NULL,
                correlation_id VARCHAR(36),
                accessed_at TIMESTAMP DEFAULT NOW() NOT NULL,
                file_path VARCHAR(500) NOT NULL,
                file_name VARCHAR(255) NOT NULL,
                file_size INTEGER,
                action VARCHAR(20) NOT NULL,
                ip_address VARCHAR(45),
                user_agent VARCHAR(500),
                success BOOLEAN DEFAULT TRUE NOT NULL,
                error_message TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_file_access_user_id ON file_access_logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_file_access_file_id ON file_access_logs(file_id);
            CREATE INDEX IF NOT EXISTS idx_file_access_correlation_id ON file_access_logs(correlation_id);
            CREATE INDEX IF NOT EXISTS idx_file_access_accessed_at ON file_access_logs(accessed_at);
            CREATE INDEX IF NOT EXISTS idx_file_access_user_accessed ON file_access_logs(user_id, accessed_at);
            CREATE INDEX IF NOT EXISTS idx_file_access_file_accessed ON file_access_logs(file_id, accessed_at);
        """))
        
        conn.commit()
        print("✓ scan_logs and file_access_logs tables created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS file_access_logs CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS scan_logs CASCADE;"))
        conn.commit()
        print("✓ Tables dropped")

if __name__ == "__main__":
    print("Running migration: add_logging_tables")
    upgrade()
    print("Migration completed!")
