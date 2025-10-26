from flask import Blueprint
from flask_login import UserMixin
from datetime import datetime
from app import db
from datetime import datetime
import pytz
from werkzeug.security import generate_password_hash, check_password_hash

egypt_time = pytz.timezone('Africa/Cairo')

# ----------------------------------
# Customer
# ----------------------------------
class Customer(db.Model, UserMixin):
    __tablename__ = 'customer'
    id            = db.Column(db.Integer, primary_key=True)
    email         = db.Column(db.String(100), unique=True)
    username      = db.Column(db.String(100))
    password_hash = db.Column(db.String(256))
    date_joined   = db.Column(db.DateTime, default=lambda: datetime.now(egypt_time))
    is_admin      = db.Column(db.Boolean, default=False)

    cart_items = db.relationship('Cart',     backref='customer', lazy=True, cascade='all, delete-orphan')
    orders     = db.relationship('Order',    backref='customer', lazy=True, cascade='all, delete-orphan')
    wishlist   = db.relationship('Wishlist', backref='customer', lazy=True, cascade='all, delete-orphan')

    @property
    def password(self):
        raise AttributeError("password is write only")
    
    @password.setter
    def password(self, raw_password):
        self.password_hash = generate_password_hash(password=raw_password)

    def verify_password(self, raw_password):
        return check_password_hash(self.password_hash, raw_password)

    def __repr__(self):
        return f'<Customer {self.id}>'


# ----------------------------------
# Category
# ----------------------------------
class Category(db.Model):
    __tablename__ = 'categories'
    catID       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    catName     = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)

    products = db.relationship('Product', backref='category', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f"<Category {self.catName}>"


# ----------------------------------
# Product
# ----------------------------------
class Product(db.Model):
    __tablename__ = 'products'
    pID                = db.Column(db.Integer, primary_key=True, autoincrement=True)
    productName        = db.Column(db.String(100), nullable=False)
    productPrice       = db.Column(db.Float, nullable=False)
    description        = db.Column(db.Text, nullable=False)
    category_id        = db.Column(db.Integer, db.ForeignKey('categories.catID'), nullable=False)
    date_added         = db.Column(db.DateTime, default=lambda: datetime.now(egypt_time))
    is_featured        = db.Column(db.Boolean, default=False)

    photos      = db.relationship('ProductPhoto', backref='product', lazy=True, cascade='all, delete-orphan')
    sizes       = db.relationship('ProductSize',  backref='product', lazy=True, cascade='all, delete-orphan')
    cart_items  = db.relationship('Cart',         backref='product', lazy=True, cascade='all, delete-orphan')
    orders      = db.relationship('Order',        backref='product', lazy=True, cascade='all, delete-orphan')
    wish_items  = db.relationship('Wishlist',     backref='product', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f"Product(id={self.pID}, name={self.productName})"

    def to_dict(self):
        return {
            'id': self.pID,
            'title': self.productName,
            'price': self.productPrice,
            'description': self.description,
            'category_id': self.category_id,
            'date_added': self.date_added.isoformat(),
            'is_featured': self.is_featured,
            'images': [photo.image_url for photo in self.photos]  # Assuming each photo has an 'image_url' field
        }

# ----------------------------------
# ProductPhoto
# ----------------------------------
class ProductPhoto(db.Model):
    __tablename__ = 'product_photos'
    photoID    = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.pID'), nullable=False)
    image_url  = db.Column(db.String(1024), nullable=False)
    photo_order= db.Column(db.Integer, default=0)

    def __repr__(self):
        return f"<Photo {self.photoID} for Product {self.product_id}>"


    

# ----------------------------------
# ProductSize (per-size inventory)
# ----------------------------------
class ProductSize(db.Model):
    __tablename__ = 'product_sizes'
    sizeID     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.pID'), nullable=False)
    size_label = db.Column(db.String(50), nullable=False)  # e.g. "S", "M", "L", "XL"
    quantity   = db.Column(db.Integer, nullable=False)

    def __repr__(self):
        return f"<Size {self.size_label} ({self.quantity}) for Product {self.product_id}>"


# ----------------------------------
# Cart
# ----------------------------------
class Cart(db.Model):
    __tablename__ = 'cart'
    cartID      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customer.id'), nullable=False)
    product_id  = db.Column(db.Integer, db.ForeignKey('products.pID'), nullable=False)
    size_id     = db.Column(db.Integer, db.ForeignKey('product_sizes.sizeID'), nullable=False)
    quantity    = db.Column(db.Integer, nullable=False)
    added_at    = db.Column(db.DateTime, default=lambda: datetime.now(egypt_time))

    size = db.relationship('ProductSize')

    def __repr__(self):
        return (f"<Cart {self.cartID}: Cust {self.customer_id} × "
                f"Prod {self.product_id} (size={self.size.size_label}, qty={self.quantity})>")


# ----------------------------------
# Order
# ----------------------------------
class Order(db.Model):
    __tablename__ = 'orders'
    orderID     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customer.id'), nullable=False)
    product_id  = db.Column(db.Integer, db.ForeignKey('products.pID'), nullable=False)
    size_id     = db.Column(db.Integer, db.ForeignKey('product_sizes.sizeID'), nullable=False)
    quantity    = db.Column(db.Integer, nullable=False)
    unit_price  = db.Column(db.Float, nullable=False)
    status      = db.Column(db.Enum('pending','shipped','delivered','canceled', name='order_status'),
                            default='pending', nullable=False)
    payment_id  = db.Column(db.String(1000), nullable=False)
    ordered_at  = db.Column(db.DateTime, default=lambda: datetime.now(egypt_time))
    name        = db.Column(db.String(255), nullable=True)
    email       = db.Column(db.String(255), nullable=True)
    address     = db.Column(db.Text, nullable=True)

    size = db.relationship('ProductSize')

    def __repr__(self):
        return (f"<Order {self.orderID}: Cust {self.customer_id}, "
                f"Prod {self.product_id}, size={self.size.size_label}, status={self.status}>")


# ----------------------------------
# Wishlist
# ----------------------------------
class Wishlist(db.Model):
    __tablename__ = 'wishlist'
    wishID      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customer.id'), nullable=False)
    product_id  = db.Column(db.Integer, db.ForeignKey('products.pID'), nullable=False)
    added_at    = db.Column(db.DateTime, default=lambda: datetime.now(egypt_time))

    def __repr__(self):
        return f"<Wishlist {self.wishID}: Cust {self.customer_id} → Prod {self.product_id}>"
