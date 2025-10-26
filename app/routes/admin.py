import os
from datetime import datetime, timedelta
from flask import Blueprint, render_template, request,redirect, url_for, flash, current_app
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from app.models import db, Product, ProductPhoto, ProductSize, Category, Order, Customer

admin = Blueprint('admin', __name__)

# Allowed image extensions
ALLOWED_EXT = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXT



############ add product #########

@admin.route('/addpd', methods=['GET', 'POST'], endpoint='addpd')
@login_required
def addpd():
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    categories = Category.query.all()
    if request.method == 'POST':
        productName = request.form.get('productName')
        productPrice = request.form.get('productPrice')
        description = request.form.get('description')
        category_id = request.form.get('category_id')
        is_featured = request.form.get('is_featured') == 'on'
        photos = request.files.getlist('photos[]')
        size_labels = request.form.getlist('size_label[]')
        size_qtys = request.form.getlist('size_qty[]')
        # Read photo order from form
        photo_orders = []
        for idx in range(len(photos)):
            order = int(request.form.get(f'photo_order_{idx}', idx+1))
            photo_orders.append((order, idx, photos[idx]))
        # Sort by order (1 = main)
        photo_orders.sort()

        if not all([productName, productPrice, description, category_id, photos]):
            flash('Please fill in all required fields and upload at least one photo!', 'danger')
            return redirect(url_for('admin.addpd'))

        try:
            productPrice = float(productPrice)
        except ValueError:
            flash('Invalid price!', 'danger')
            return redirect(url_for('admin.addpd'))

        new_product = Product(
            productName=productName,
            productPrice=productPrice,
            description=description,
            category_id=category_id,
            is_featured=is_featured
        )
        db.session.add(new_product)
        db.session.flush()

        for idx, (order, orig_idx, photo) in enumerate(photo_orders):
            if photo and allowed_file(photo.filename):
                filename = secure_filename(photo.filename)
                photo.save(os.path.join(current_app.config['UPLOAD_FOLDER'], filename))
                product_photo = ProductPhoto(
                    product_id=new_product.pID,
                    image_url=filename,
                    photo_order=idx
                )
                db.session.add(product_photo)
            else:
                db.session.rollback()
                flash('Invalid image format! Allowed formats are: png, jpg, jpeg, gif', 'danger')
                return redirect(url_for('admin.addpd'))

        for label, qty in zip(size_labels, size_qtys):
            if label.strip() and qty.strip():
                try:
                    quantity = int(qty)
                    if quantity < 0:
                        raise ValueError
                    size = ProductSize(
                        product_id=new_product.pID,
                        size_label=label.strip(),
                        quantity=quantity
                    )
                    db.session.add(size)
                except ValueError:
                    db.session.rollback()
                    flash('Invalid quantity for size ' + label, 'danger')
                    return redirect(url_for('admin.addpd'))

        try:
            db.session.commit()
            flash('Product added successfully!', 'success')
            return redirect(url_for('admin.dashboard'))
        except Exception as e:
            db.session.rollback()
            flash('Error adding product: ' + str(e), 'danger')
            return redirect(url_for('admin.addpd'))

    return render_template('addnew.html', categories=categories)

@admin.route('/dashboard', endpoint='dashboard')
@login_required
def dashboard():
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Category
    orders = Order.query.order_by(Order.ordered_at.desc()).all()
    total_sales = sum(o.unit_price * o.quantity for o in orders)
    total_units_sold = sum(o.quantity for o in orders)
    today = datetime.now()
    sales_trend = []
    for i in range(29, -1, -1):
        day = today - timedelta(days=i)
        day_orders = [o for o in orders if o.ordered_at.date() == day.date()]
        day_sales = sum(o.unit_price * o.quantity for o in day_orders)
        sales_trend.append({'date': day.strftime('%Y-%m-%d'), 'sales': day_sales})
    categories = Category.query.all()
    return render_template('admin_dashboard.html', orders=orders, total_sales=total_sales, total_units_sold=total_units_sold, sales_trend=sales_trend, categories=categories)

@admin.route('/update-order-status/<int:order_id>', methods=['POST'], endpoint='update_order_status')
@login_required
def update_order_status(order_id):
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Order
    order = Order.query.get_or_404(order_id)
    new_status = request.form.get('status')
    if new_status in ['pending','shipped','delivered','canceled']:
        order.status = new_status
        db.session.commit()
        flash(f'Order {order_id} status updated to {new_status}.', 'success')
    else:
        flash('Invalid status.', 'danger')
    return redirect(url_for('admin.dashboard'))

@admin.route('/categories', methods=['GET', 'POST'], endpoint='categories')
@login_required
def categories():
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Category
    if request.method == 'POST':
        cat_name = request.form.get('catName')
        cat_desc = request.form.get('catDesc')
        if cat_name:
            new_cat = Category(catName=cat_name, description=cat_desc)
            db.session.add(new_cat)
            db.session.commit()
            flash('Category added!', 'success')
        return redirect(url_for('admin.dashboard'))
    return redirect(url_for('admin.dashboard'))

@admin.route('/delete-category/<int:cat_id>', methods=['POST'], endpoint='delete_category')
@login_required
def delete_category(cat_id):
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Category
    cat = Category.query.get_or_404(cat_id)
    db.session.delete(cat)
    db.session.commit()
    flash('Category deleted!', 'success')
    return redirect(url_for('admin.dashboard'))

@admin.route('/delete-products', methods=['GET', 'POST'], endpoint='delete_products')
@login_required
def delete_products():
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Product
    if request.method == 'POST':
        product_id = request.form.get('product_id')
        product = Product.query.get(product_id)
        if product:
            db.session.delete(product)
            db.session.commit()
            flash('Product deleted!', 'success')
        return redirect(url_for('admin.delete_products'))
    products = Product.query.all()
    return render_template('delete_products.html', products=products)

@admin.route('/edit-products', methods=['GET'], endpoint='edit_products')
@login_required
def edit_products():
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Product
    products = Product.query.all()
    return render_template('edit_products.html', products=products)

@admin.route('/edit-product/<int:product_id>', methods=['GET', 'POST'], endpoint='edit_product')
@login_required
def edit_product(product_id):
    if current_user.id != 11:
        flash('Admins only!', 'danger')
        return redirect(url_for('views.homepage'))
    from app.models import Product, Category
    product = Product.query.get_or_404(product_id)
    categories = Category.query.all()
    if request.method == 'POST':
        product.productName = request.form.get('productName')
        product.productPrice = request.form.get('productPrice')
        product.description = request.form.get('description')
        product.category_id = request.form.get('category_id')
        product.is_featured = request.form.get('is_featured') == 'on'
        db.session.commit()
        flash('Product updated!', 'success')
        return redirect(url_for('admin.edit_products'))
    return render_template('edit_product.html', product=product, categories=categories)
