from flask import Flask
from app.models import Product,Category,ProductPhoto,Cart
from app import db,api
from flask import Flask,render_template,request, redirect, url_for, jsonify
from flask_restful import Api,Resource,reqparse,abort,fields,marshal_with   
from flask_login import login_required, current_user

from flask import Flask
from flask import Blueprint
api_bp = Blueprint('api',__name__)
api = Api(api_bp)

from app.resources import ProductResource,CategoryResource,ProductPhotoResource

api.add_resource(ProductResource, "/product/<int:pID>")
api.add_resource(CategoryResource, "/categories/<int:catID>")
api.add_resource(ProductPhotoResource, "/photos/<int:photoID>")


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

@api_bp.route('/products', methods=['GET'])
def get_products():
    query = request.args.get('query', '').strip().lower()
    all_products = Product.query.all()
    filtered_products = []

    for product in all_products:    
        product_dict = product.to_dict()
        if not query or query in product_dict['title'].lower():
            filtered_products.append(product_dict)

    return jsonify(filtered_products)

@api_bp.route('/search', methods=['GET'])
def api_search():
    query = request.args.get('q', '').strip().lower()
    if not query or len(query) < 2:
        return jsonify([])

    products = Product.query.join(Category).filter(
        (Product.productName.ilike(f"%{query}%")) |
        (Product.description.ilike(f"%{query}%")) |
        (Category.catName.ilike(f"%{query}%"))
    ).all()

    return jsonify([
        {
            'id': p.pID,
            'name': p.productName,
            'price': p.productPrice,
            'image': p.photos[0].image_url if p.photos else '/static/img/default.jpg'
        }
        for p in products
    ])

@api_bp.route('/update-cart-item', methods=['POST'])
@login_required
def update_cart_item():
    data = request.get_json()
    cart_item_id = data.get('cart_item_id')
    quantity = data.get('quantity')
    if not cart_item_id or quantity is None:
        return jsonify({'success': False, 'message': 'cart_item_id and quantity are required'}), 400
    try:
        cart_item = Cart.query.filter_by(cartID=cart_item_id, customer_id=current_user.id).first()
        if not cart_item:
            return jsonify({'success': False, 'message': 'Cart item not found'}), 404
        if quantity < 1:
            return jsonify({'success': False, 'message': 'Quantity must be at least 1'}), 400
        cart_item.quantity = quantity
        db.session.commit()
        return jsonify({'success': True, 'message': 'Cart item updated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@api_bp.route('/remove-cart-item', methods=['POST'])
@login_required
def remove_cart_item():
    data = request.get_json()
    cart_item_id = data.get('cart_item_id')
    if not cart_item_id:
        return jsonify({'success': False, 'message': 'cart_item_id is required'}), 400
    try:
        cart_item = Cart.query.filter_by(cartID=cart_item_id, customer_id=current_user.id).first()
        if not cart_item:
            return jsonify({'success': False, 'message': 'Cart item not found'}), 404
        db.session.delete(cart_item)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Cart item removed'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
