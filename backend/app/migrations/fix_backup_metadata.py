"""
Fix script to update backup_history table schema

Run this to fix the column name issue:
python -m app.migrations.fix_backup_metadata
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Check if the old 'metadata' column exists
        result = conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='backup_history' AND column_name='metadata';
        """))
        
        if result.fetchone():
            print("Found old 'metadata' column. Renaming to 'backup_metadata'...")
            conn.execute(text("""
                ALTER TABLE backup_history 
                RENAME COLUMN metadata TO backup_metadata;
            """))
            conn.commit()
            print("✓ Column renamed successfully")
        else:
            # Check if backup_metadata already exists
            result = conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name='backup_history' AND column_name='backup_metadata';
            """))
            
            if result.fetchone():
                print("✓ Column 'backup_metadata' already exists. No changes needed.")
            else:
                # Column doesn't exist at all, add it
                print("Adding 'backup_metadata' column...")
                conn.execute(text("""
                    ALTER TABLE backup_history 
                    ADD COLUMN backup_metadata JSONB;
                """))
                conn.commit()
                print("✓ Column added successfully")

if __name__ == "__main__":
    print("Running migration: fix_backup_metadata")
    upgrade()
    print("Migration completed!")
