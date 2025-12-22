"""
Migration script to create backup_history and operation_lock tables

Run this script to add the new tables for backup/restore functionality:
python -m app.migrations.add_backup_tables
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create backup_history table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS backup_history (
                id SERIAL PRIMARY KEY,
                filename VARCHAR(255) NOT NULL UNIQUE,
                file_path VARCHAR(512) NOT NULL,
                file_size BIGINT,
                backup_type VARCHAR(50) DEFAULT 'manual',
                created_by_id INTEGER REFERENCES users(id),
                created_at TIMESTAMP DEFAULT NOW(),
                status VARCHAR(50) DEFAULT 'completed',
                backup_metadata JSONB,
                notes TEXT
            );
        """))
        
        # Create operation_lock table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS operation_lock (
                id SERIAL PRIMARY KEY,
                operation_type VARCHAR(50) NOT NULL,
                locked_by_id INTEGER REFERENCES users(id),
                locked_at TIMESTAMP DEFAULT NOW(),
                status VARCHAR(50) DEFAULT 'in_progress'
            );
        """))
        
        conn.commit()
        print("✓ Tables created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS backup_history CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS operation_lock CASCADE;"))
        conn.commit()
        print("✓ Tables dropped successfully")

if __name__ == "__main__":
    print("Running migration: add_backup_tables")
    upgrade()
    print("Migration completed!")
