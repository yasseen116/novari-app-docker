from flask import Blueprint, render_template, request, abort, flash, session
from flask import Flask,render_template,request, redirect, url_for, jsonify
from flask_restful import Api,Resource,reqparse,abort,fields,marshal_with
from flask_sqlalchemy import SQLAlchemy
from app.models import Product, Category, Order, Cart, Wishlist
from datetime import datetime
import stripe
from flask_login import login_required, current_user
import logging
from app import db
from werkzeug.security import check_password_hash, generate_password_hash
import requests
from sqlalchemy import func


views = Blueprint('views', __name__)

# Stripe test keys (replace with your own test keys if needed)
stripe.api_key = 'sk_test_51N...'  # Use your Stripe test secret key

@views.route("/")
def homepage():
    return render_template("homepage.html", pagetitle="Novari - Fashion for the Modern Duo", endpoint='views.homepage')

@views.route("/index.html")
def homepage1():
    return render_template("homepage.html", pagetitle="Novari - Fashion for the Modern Duo")


@views.route("/cart.html", endpoint='cart')
@login_required
def cart():
    cart_items = Cart.query.filter_by(customer_id=current_user.id).all()
    return render_template("cart.html", pagetitle="cart", cart_items=cart_items)


@views.route("/contact", methods=['GET', 'POST'])
@views.route("/contact.html", methods=['GET', 'POST'], endpoint='contact')
def contact():
    if request.method == 'POST':
        name = request.form.get('name')
        email = request.form.get('email')
        message = request.form.get('message')
        if not name or not email or not message:
            return {'success': False, 'message': 'All fields are required.'}, 400
        bot_token = '8130303907:AAEJSDm17X9WXLc6pXJTETmQh3oFnHaebbs'
        chat_ids = ['7045694576', '5325140914']
        text = f"""
📥 New Contact Message:
👤 Name: {name}
✉️ Email: {email}
📝 Message: {message}
"""
        success = True
        for chat_id in chat_ids:
            url = f'https://api.telegram.org/bot{bot_token}/sendMessage'
            payload = {'chat_id': chat_id, 'text': text}
            try:
                resp = requests.post(url, data=payload, timeout=10)
                if not resp.ok:
                    success = False
            except Exception as e:
                success = False
        if success:
            return {'success': True, 'message': 'Message sent!'}, 200
        else:
            return {'success': False, 'message': 'Failed to send message.'}, 500
    return render_template('contact.html', pagetitle='contact')


@views.route("/shop.html", endpoint='shop')
def shop():
    category = request.args.get('category', '').strip().lower()
    price = request.args.get('price', '').strip()
    rating = request.args.get('rating', '').strip()
    sort = request.args.get('sort', '').strip()

    query = Product.query

    # Category filter
    if category:
        query = query.join(Category).filter(func.lower(Category.catName) == category)
    
    # Price filter
    if price:
        if price == '0-500':
            query = query.filter(Product.productPrice >= 0, Product.productPrice <= 500)
        elif price == '500-1500':
            query = query.filter(Product.productPrice > 500, Product.productPrice <= 1500)
        elif price == '1500-3000':
            query = query.filter(Product.productPrice > 1500, Product.productPrice <= 3000)
        elif price == '3000+':
            query = query.filter(Product.productPrice > 3000)

    # Rating filter
    if rating and rating.isdigit():
        query = query.filter(Product.rating >= int(rating))

    # Sorting
    if sort == 'price-asc':
        query = query.order_by(Product.productPrice.asc())
    elif sort == 'price-desc':
        query = query.order_by(Product.productPrice.desc())
    elif sort == 'name-asc':
        query = query.order_by(Product.productName.asc())
    elif sort == 'name-desc':
        query = query.order_by(Product.productName.desc())
    elif sort == 'rating-desc':
        query = query.order_by(Product.rating.desc())

    products = query.all()
    categories = Category.query.all()

    # If it's an AJAX request, return JSON
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        products_data = [{
            'id': p.pID,
            'name': p.productName,
            'price': p.productPrice,
            'category': p.category.catName if p.category else '',
            'image': p.photos[0].image_url if p.photos else 'img/default.jpg',
            'rating': p.rating if hasattr(p, 'rating') else 5
        } for p in products]
        return jsonify({
            'products': products_data,
            'count': len(products)
        })

    # Regular request - return full page
    return render_template("shop.html", 
                         pagetitle="shop", 
                         products=products, 
                         categories=categories,
                         current_category=category,
                         current_price=price,
                         current_rating=rating,
                         current_sort=sort)

@views.route("/favorites.html", endpoint='favorites')
@login_required
def favorites():
    from app.models import Wishlist
    # Query the current user's wishlist, join with Product for details
    wishlist_items = Wishlist.query.filter_by(customer_id=current_user.id).all()
    return render_template("favorites.html", pagetitle="favorites", favorites=wishlist_items)

@views.route("/profile.html", endpoint='profile')
@login_required
def profile():
    return render_template('profile.html', user=current_user)

@views.route('/orders.html', endpoint='orders')
@login_required
def orders():
    from app.models import Order
    user_orders = Order.query.filter_by(customer_id=current_user.id).order_by(Order.ordered_at.desc()).all()
    return render_template('orders.html', orders=user_orders)

@views.route('/search')
def search():
    query = request.args.get('query', '').strip()
    if not query:
        return render_template('search.html', 
                             products=[], 
                             query=query,
                             pagetitle="Search Results")
    
    products = Product.query.filter(
        Product.productName.ilike(f"%{query}%")
    ).all()
    
    return render_template('search.html', 
                         products=products, 
                         query=query,
                         pagetitle=f"Search Results for: {query}")

@views.route('/product/<int:pID>.html')
def product_details(pID):
    try:
        product = Product.query.get_or_404(pID)
        return render_template('product.html', 
                            product=product,
                            pagetitle=product.productName)
    except Exception as e:
        abort(404)

@views.route('/checkout', methods=['GET', 'POST'])
@login_required
def checkout():
    cart_items = Cart.query.filter_by(customer_id=current_user.id).all()
    if request.method == 'POST':
        name = request.form.get('name')
        address = request.form.get('address')
        email = request.form.get('email')
        payment_type = request.form.get('payment_type')
        if not cart_items:
            flash('Your cart is empty.', 'danger')
            return redirect(url_for('views.cart'))
        total = sum(item.quantity * item.product.productPrice for item in cart_items)
        try:
            payment_id = None
            if payment_type == 'card':
                payment_id = 'test_payment_id'
            elif payment_type == 'cod':
                payment_id = 'cash_on_delivery'
            else:
                flash('Invalid payment type.', 'danger')
                return redirect(url_for('views.checkout'))
            # Store order for each cart item
            for item in cart_items:
                order = Order(
                    customer_id=current_user.id,
                    product_id=item.product_id,
                    size_id=item.size_id,
                    quantity=item.quantity,
                    unit_price=item.product.productPrice,
                    status='pending',
                    payment_id=payment_id,
                    name=name,
                    email=email,
                    address=address
                )
                db.session.add(order)
            db.session.commit()
            # Clear cart
            for item in cart_items:
                db.session.delete(item)
            db.session.commit()
            return redirect(url_for('views.order_confirmation'))
        except Exception as e:
            db.session.rollback()
            flash('Payment failed or order error: ' + str(e), 'danger')
    return render_template('checkout.html', pagetitle='Checkout', cart_items=cart_items)

@views.route('/order-confirmation')
def order_confirmation():
    # For demo, just show a simple confirmation
    return render_template('order_confirmation.html', pagetitle='Order Confirmation')

@views.route('/add-to-cart', methods=['POST'])
@login_required
def add_to_cart():
    try:
        data = request.get_json()
        product_id = data.get('product_id')
        size_label = data.get('size')
        quantity = int(data.get('quantity', 1))
        if not product_id or not size_label:
            return jsonify({'success': False, 'message': 'Missing product or size'}), 400
        product = Product.query.get(product_id)
        if not product:
            return jsonify({'success': False, 'message': 'Product not found'}), 404
        size_obj = None
        for s in product.sizes:
            if s.size_label == size_label:
                size_obj = s
                break
        if not size_obj:
            return jsonify({'success': False, 'message': 'Invalid size'}), 400
        cart_item = Cart.query.filter_by(customer_id=current_user.id, product_id=product_id, size_id=size_obj.sizeID).first()
        if cart_item:
            cart_item.quantity += quantity
        else:
            cart_item = Cart(customer_id=current_user.id, product_id=product_id, size_id=size_obj.sizeID, quantity=quantity)
            db.session.add(cart_item)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Added to cart'})
    except Exception as e:
        logging.exception('Error in add_to_cart')
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@views.route('/add-to-wishlist', methods=['POST'])
@login_required
def add_to_wishlist():
    try:
        data = request.get_json()
        product_id = data.get('product_id')
        if not product_id:
            return jsonify({'success': False, 'message': 'Missing product id'}), 400
        product = Product.query.get(product_id)
        if not product:
            return jsonify({'success': False, 'message': 'Product not found'}), 404
        wish_item = Wishlist.query.filter_by(customer_id=current_user.id, product_id=product_id).first()
        if wish_item:
            return jsonify({'success': False, 'message': 'Already in wishlist'}), 400
        wish_item = Wishlist(customer_id=current_user.id, product_id=product_id)
        db.session.add(wish_item)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Added to wishlist'})
    except Exception as e:
        logging.exception('Error in add_to_wishlist')
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@views.route('/remove-from-wishlist', methods=['POST'])
@login_required
def remove_from_wishlist():
    try:
        data = request.get_json()
        product_id = data.get('product_id')
        if not product_id:
            return jsonify({'success': False, 'message': 'Missing product id'}), 400
        wish_item = Wishlist.query.filter_by(customer_id=current_user.id, product_id=product_id).first()
        if not wish_item:
            return jsonify({'success': False, 'message': 'Item not found in wishlist'}), 404
        db.session.delete(wish_item)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Removed from wishlist'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

@views.app_context_processor
def inject_cart_count():
    from flask_login import current_user
    from app.models import Cart
    if hasattr(current_user, 'is_authenticated') and current_user.is_authenticated:
        count = Cart.query.filter_by(customer_id=current_user.id).count()
    else:
        count = 0
    return dict(cart_count=count)

@views.route('/addnew', endpoint='addnew')
@login_required
def addnew():
    from app.models import Category
    categories = Category.query.all()
    return render_template('addnew.html', categories=categories)

@views.route('/change-password/<int:customer_id>', methods=['POST'], endpoint='changepassword')
@login_required
def change_password(customer_id):
    if current_user.id != customer_id:
        abort(403)
    current_password = request.form.get('current_password')
    new_password = request.form.get('new_password')
    confirm_new_password = request.form.get('confirm_new_password')
    if not check_password_hash(current_user.password, current_password):
        flash('Current password is incorrect.', 'danger')
        return redirect(url_for('views.profile'))
    if new_password != confirm_new_password:
        flash('New passwords do not match.', 'danger')
        return redirect(url_for('views.profile'))
    if len(new_password) < 6:
        flash('New password must be at least 6 characters.', 'danger')
        return redirect(url_for('views.profile'))
    current_user.password = generate_password_hash(new_password)
    db.session.commit()
    flash('Password changed successfully!', 'success')
    return redirect(url_for('views.profile'))

@views.route('/cancel-order/<int:order_id>', methods=['POST'], endpoint='cancel_order')
@login_required
def cancel_order(order_id):
    from app.models import Order
    order = Order.query.get_or_404(order_id)
    if order.customer_id != current_user.id or order.status != 'pending':
        abort(403)
    order.status = 'canceled'
    db.session.commit()
    flash('Order canceled successfully.', 'success')
    return redirect(url_for('views.orders'))

@views.route("/privacy-policy")
def privacy_policy():
    return render_template("privacy_policy.html", pagetitle="Privacy Policy")