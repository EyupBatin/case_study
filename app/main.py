from fastapi import FastAPI
from app.api import users, products
import socket
from fastapi.middleware.cors import CORSMiddleware

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    finally:
        s.close()

print("IPv4 Adresiniz:", get_local_ip())

app = FastAPI(
    title="Ürün Takip API",
    version="1.0.0",
)

asgi_app = app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(products.router, prefix="/products", tags=["Products"])


@app.get("/")
def root():
    return {"message": "Backend çalışıyor!"}
