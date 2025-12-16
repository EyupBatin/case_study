from sqlalchemy import Column,Integer,String,Boolean,Float
from app.database import Base

class Users(Base):
    __tablename__= "users"
    id = Column(Integer,primary_key=True,index=True)
    first_name = Column(String,nullable=False)
    last_name = Column(String,nullable=False)
    email = Column(String,unique=True,index=True,nullable=False)
    password = Column(String,nullable=False)
    refresh_token = Column(String, nullable=True)
    is_active = Column(Boolean,default=True)

class Product(Base):
    __tablename__="products"
    id = Column(Integer,primary_key=True,index=True)
    type = Column(String,nullable=False)
    name = Column(String,nullable=False)
    count = Column(Integer,default=0)


