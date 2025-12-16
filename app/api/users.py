from fastapi import HTTPException, APIRouter,Body,status
from fastapi.params import Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.auth import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.database import SessionLocal,engine
from app.models import Users

router= APIRouter(include_in_schema=True)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register", summary="Kullanıcı kaydı", tags=["Users"])
def register(data:dict=Body(...),db=Depends(get_db)):
    if db.query(Users).filter(Users.email == data["email"]).first():
        raise HTTPException(status_code=400,detail="Email zaten kayıtlı")

    user= Users(
        first_name = data.get("name") or data.get("first_name"),
        last_name = data.get("surname") or data.get("last_name"),
        email = data["email"],
        password = hash_password(data["password"])
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return  {"message":"ok"}

@router.post("/login", summary="Kullanıcı girişi", tags=["Users"])
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):

    user = db.query(Users).filter(Users.email == form_data.username).first()

    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(status_code=401, detail="Email veya parola hatalı")

    access_token = create_access_token({"user_id": user.id})
    refresh_token = create_refresh_token({"user_id": user.id})

    # Refresh token DB'ye kaydediliyor
    user.refresh_token = refresh_token
    db.commit()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }
@router.post("/refresh", summary="Yeni access token al")
def refresh_token(data: dict = Body(...), db: Session = Depends(get_db)):
    # Hem "token" hem de "refresh_token" key'lerini kabul et
    token = data.get("token") or data.get("refresh_token")
    
    if not token:
        raise HTTPException(
            status_code=422, 
            detail="Token gerekli. Body'de 'token' veya 'refresh_token' key'i olmalı."
        )
    
    try:
        payload = decode_token(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(status_code=401, detail="Refresh token geçersiz")

    user = db.query(Users).filter(Users.id == user_id).first()

    if not user or user.refresh_token != token:
        raise HTTPException(status_code=401, detail="Refresh token bulunamadı")

    # Yeni access token üret
    new_access_token = create_access_token({"user_id": user.id})

    return {"access_token": new_access_token, "token_type": "bearer"}
