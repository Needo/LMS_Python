"""
Add refresh_tokens table for JWT refresh token management

Run: python -m app.migrations.add_refresh_tokens
"""

from sqlalchemy import create_engine, text
from app.core.config import settings

def upgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS refresh_tokens (
                id SERIAL PRIMARY KEY,
                token VARCHAR(500) UNIQUE NOT NULL,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT NOW(),
                revoked BOOLEAN DEFAULT FALSE
            );
            
            CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
            CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
        """))
        
        conn.commit()
        print("✓ refresh_tokens table created successfully")

def downgrade():
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS refresh_tokens CASCADE;"))
        conn.commit()
        print("✓ refresh_tokens table dropped")

if __name__ == "__main__":
    print("Running migration: add_refresh_tokens")
    upgrade()
    print("Migration completed!")
