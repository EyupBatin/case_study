from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker,declarative_base
import os

DATABASE_URL = os.getenv("DATABASE_URL","postgresql://postgres:1234@db:5432/urun_takibi")
engine = create_engine(DATABASE_URL,pool_pre_ping=True,echo=True)
SessionLocal = sessionmaker(autocommit=False,autoflush=False,bind=engine)
Base = declarative_base()
def test_connection():
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("DB bağlantısı OK:", result.scalar())
    except Exception as e:
        print("DB bağlantı hatası:", e)