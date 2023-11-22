from flask import Flask
from flask_cors import CORS
from flask_restx import Resource, Api
from flask_pymongo import PyMongo
from pymongo.collection import Collection
from .model import Swiss

# configure flask & flask-pymongo
app = Flask(__name__)
# allow access from any frontend
cors = CORS()
cors.init_app(app, resources={r"*": {"origins": "*"}})
# add your mongodb URI
app.config['MONGO_URI'] = 'mongodb://localhost:27017/pdspdatabase'
pymongo = PyMongo(app)
# get a reference to the collection
pdspdata: Collection = pymongo.db.pdspdata
api = Api(app)
class List(Resource):
  def get(self):
    cursor = pdspdata.find()
    return [ Swiss(**doc).to_json() for doc in cursor ]  

class Data(Resource):
  def get(self, id):
    cursor = pdspdata.find_one_or_404({"id": id})
    pdspdata_ind = Swiss(**cursor)
    # do preprocessing, machine lerarning etc.
    return pdspdata_ind.to_json()

api.add_resource(List, '/pdspdata')
api.add_resource(Data, '/pdspdata/<int:id>')