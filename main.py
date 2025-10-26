from flask import Flask,render_template,request, redirect, url_for, jsonify
from flask_restful import Api,Resource,reqparse,abort,fields,marshal_with
from flask_sqlalchemy import SQLAlchemy
from flask_wtf import FlaskForm
from wtforms import StringField,SubmitField,FileField
from wtforms.validators import DataRequired
import mysql.connector
from datetime import datetime
from werkzeug.utils import secure_filename
from app import create_app
from flask_login import current_user


app = create_app()


if(__name__ =="__main__"):
    app.run(host="0.0.0.0", port=8001, debug=False)



