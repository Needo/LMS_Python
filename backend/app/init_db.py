from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine, Base
from app.models import User

def init_db():
    """
    Initialize database with default admin user.
    """
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        # Check if admin user exists
        admin = db.query(User).filter(User.username == "admin").first()
        
        if not admin:
            # Create default admin user WITHOUT password hashing for now
            print("Creating admin user with simple password...")
            admin = User(
                username="admin",
                email="admin@lms.com",
                hashed_password="admin123",  # Temporarily store plain text
                is_admin=True
            )
            db.add(admin)
            db.commit()
            print("✓ Default admin user created (username: admin, password: admin123)")
            print("⚠ WARNING: Password is stored in plain text - fix this in production!")
        else:
            print("✓ Admin user already exists")
        
        print("✓ Database initialized successfully")
        
    except Exception as e:
        print(f"✗ Error initializing database: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("Initializing database...")
    init_db()
