from flask import Flask
from app.models import Product,Category,ProductPhoto
from app import db,api
from flask import Flask,render_template,request, redirect, url_for, jsonify
from flask_restful import Api,Resource,reqparse,abort,fields,marshal_with


# ----------------------------------
# Request Parsers for API Endpoints
# ----------------------------------
# Parsers for Product endpoints
product_put_args = reqparse.RequestParser()
product_put_args.add_argument("pName", type=str, help="Product name required", required=True)
product_put_args.add_argument("pPrice", type=float, help="Product price required", required=True)
product_put_args.add_argument("description", type=str, help="Product description required", required=True)
product_put_args.add_argument("availableQuantity", type=int, help="Available quantity required", required=True)
product_put_args.add_argument("sizes", type=str, help="Sizes required", required=True)
product_put_args.add_argument("categoryID", type=int, help="Category ID required", required=True)

product_patch_args = reqparse.RequestParser()
product_patch_args.add_argument("pName", type=str, help="Product name")
product_patch_args.add_argument("pPrice", type=float, help="Product price")
product_patch_args.add_argument("description", type=str, help="Product description")
product_patch_args.add_argument("availableQuantity", type=int, help="Available quantity")
product_patch_args.add_argument("sizes", type=str, help="Sizes")
product_patch_args.add_argument("categoryID", type=int, help="Category ID")

# Parsers for Category endpoints
category_put_args = reqparse.RequestParser()
category_put_args.add_argument("catName", type=str, help="Category name required", required=True)
category_put_args.add_argument("description", type=str, help="Category description")

category_patch_args = reqparse.RequestParser()
category_patch_args.add_argument("catName", type=str, help="Category name")
category_patch_args.add_argument("description", type=str, help="Category description")

# Parsers for Product Photo endpoints
photo_put_args = reqparse.RequestParser()
photo_put_args.add_argument("product_id", type=int, help="Product ID required", required=True)
photo_put_args.add_argument("image_url", type=str, help="Image URL required", required=True)
photo_put_args.add_argument("photo_order", type=int, help="Photo order", required=False, default=0)

photo_patch_args = reqparse.RequestParser()
photo_patch_args.add_argument("image_url", type=str, help="Image URL")
photo_patch_args.add_argument("photo_order", type=int, help="Photo order")

# ----------------------------------
# Resource Fields for Marshalling JSON Responses
# ----------------------------------

product_resource_fields = {
    'pID': fields.Integer,
    'productName': fields.String,
    'productPrice': fields.Float,
    'description': fields.String,
    'available_quantity': fields.Integer,
    'sizes': fields.String,
    'category_id': fields.Integer,
}

category_resource_fields = {
    'catID': fields.Integer,
    'catName': fields.String,
    'description': fields.String,
}

photo_resource_fields = {
    'photoID': fields.Integer,
    'product_id': fields.Integer,
    'image_url': fields.String,
    'photo_order': fields.Integer,
}


# ----------------------------------
# API Resources / Endpoints
# ----------------------------------

# Product Endpoints: GET, PUT, PATCH, DELETE for products.
class ProductResource(Resource):
    @marshal_with(product_resource_fields)
    def get(self, pID):
        product = Product.query.get(pID)
        if not product:
            abort(404, message="Product not found")
        return product

    @marshal_with(product_resource_fields)
    def put(self, pID):
        args = product_put_args.parse_args()
        if Product.query.filter_by(pID=pID).first():
            abort(409, message="Product with this ID already exists")
        product = Product(pID=pID,
                          productName=args['pName'],
                          productPrice=args['pPrice'],
                          description=args['description'],
                          available_quantity=args['availableQuantity'],
                          sizes=args['sizes'],
                          category_id=args['categoryID'])
        db.session.add(product)
        db.session.commit()
        return product, 201

    @marshal_with(product_resource_fields)
    def patch(self, pID):
        args = product_patch_args.parse_args()
        product = Product.query.get(pID)
        if not product:
            abort(404, message="Product not found")
        if args['pName']:
            product.productName = args['pName']
        if args['pPrice']:
            product.productPrice = args['pPrice']
        if args['description']:
            product.description = args['description']
        if args['availableQuantity'] is not None:
            product.available_quantity = args['availableQuantity']
        if args['sizes']:
            product.sizes = args['sizes']
        if args['categoryID']:
            product.category_id = args['categoryID']
        db.session.commit()
        return product

    def delete(self, pID):
        product = Product.query.get(pID)
        if not product:
            abort(404, message="Product not found")
        db.session.delete(product)
        db.session.commit()
        return {"message": "Product deleted"}

# Category Endpoints: GET, PUT, PATCH, DELETE for categories.
class CategoryResource(Resource):
    @marshal_with(category_resource_fields)
    def get(self, catID):
        category = Category.query.get(catID)
        if not category:
            abort(404, message="Category not found")
        return category

    @marshal_with(category_resource_fields)
    def put(self, catID):
        args = category_put_args.parse_args()
        if Category.query.filter_by(catID=catID).first():
            abort(409, message="Category with this ID already exists")
        category = Category(catID=catID,
                            catName=args['catName'],
                            description=args.get('description'))
        db.session.add(category)
        db.session.commit()
        return category, 201

    @marshal_with(category_resource_fields)
    def patch(self, catID):
        args = category_patch_args.parse_args()
        category = Category.query.get(catID)
        if not category:
            abort(404, message="Category not found")
        if args['catName']:
            category.catName = args['catName']
        if args['description'] is not None:
            category.description = args['description']
        db.session.commit()
        return category

    def delete(self, catID):
        category = Category.query.get(catID)
        if not category:
            abort(404, message="Category not found")
        db.session.delete(category)
        db.session.commit()
        return {"message": "Category deleted"}

# Product Photo Endpoints: GET, PUT, PATCH, DELETE for product photos.
class ProductPhotoResource(Resource):
    @marshal_with(photo_resource_fields)
    def get(self, photoID):
        photo = ProductPhoto.query.get(photoID)
        if not photo:
            abort(404, message="Photo not found")
        return photo

    @marshal_with(photo_resource_fields)
    def put(self, photoID):
        args = photo_put_args.parse_args()
        if ProductPhoto.query.filter_by(photoID=photoID).first():
            abort(409, message="Photo with this ID already exists")
        photo = ProductPhoto(photoID=photoID,
                             product_id=args['product_id'],
                             image_url=args['image_url'],
                             photo_order=args['photo_order'])
        db.session.add(photo)
        db.session.commit()
        return photo, 201

    @marshal_with(photo_resource_fields)
    def patch(self, photoID):
        args = photo_patch_args.parse_args()
        photo = ProductPhoto.query.get(photoID)
        if not photo:
            abort(404, message="Photo not found")
        if args['image_url']:
            photo.image_url = args['image_url']
        if args['photo_order'] is not None:
            photo.photo_order = args['photo_order']
        db.session.commit()
        return photo

    def delete(self, photoID):
        photo = ProductPhoto.query.get(photoID)
        if not photo:
            abort(404, message="Photo not found")
        db.session.delete(photo)
        db.session.commit()
        return {"message": "Photo deleted"}

# ----------------------------------
# Register API Endpoints
# ----------------------------------
api.add_resource(ProductResource, "/product/<int:pID>")
api.add_resource(CategoryResource, "/categories/<int:catID>")
api.add_resource(ProductPhotoResource, "/photos/<int:photoID>")


