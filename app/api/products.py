from fastapi import APIRouter, Body, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import SessionLocal
from app.models import Product

router = APIRouter(include_in_schema=True)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", summary="Create product", tags=["Products"])
def create_product(
    data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    for f in ("type", "name", "count"):
        if f not in data:
            raise HTTPException(status_code=422, detail=f"{f} gerekli")

    prod = Product(
        type=data["type"],
        name=data["name"],
        count=int(data["count"])
    )
    db.add(prod)
    db.commit()
    db.refresh(prod)

    return prod


@router.get("/", summary="List products", tags=["Products"])
def list_products(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    prods = db.query(Product).all()
    return prods

@router.get("/{product_id}", summary="Get product detail", tags=["Products"])
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    p = db.query(Product).filter(Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Ürün bulunamadı")
    return p


@router.put("/{product_id}", summary="Update product", tags=["Products"])
def update_product(
    product_id: int,
    data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    p = db.query(Product).filter(Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Ürün bulunamadı")

    if "type" in data:
        p.type = data["type"]
    if "name" in data:
        p.name = data["name"]
    if "count" in data:
        p.count = int(data["count"])

    db.commit()
    db.refresh(p)
    return {"message": "Güncellendi", "product": p}


@router.delete("/{product_id}", summary="Delete product", tags=["Products"])
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    p = db.query(Product).filter(Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Ürün bulunamadı")

    db.delete(p)
    db.commit()
    return {"message": "Ürün silindi"}
