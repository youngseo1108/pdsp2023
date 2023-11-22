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
app.config['MONGO_URI'] = 'mongodb://localhost:27017/pdsp'
pymongo = PyMongo(app)
# get a reference to the collection
swiss: Collection = pymongo.db.pdsp
api = Api(app)
class SwissList(Resource):
  def get(self):
    cursor = swiss.find()
    return [ Swiss(**doc).to_json() for doc in cursor ]  

class SwissData(Resource):
  def get(self, id):
    cursor = swiss.find_one_or_404({"id": id})
    swiss = Swiss(**cursor)
    # do preprocessing, machine lerarning etc.
    return swiss.to_json()

api.add_resource(SwissList, '/swiss')
api.add_resource(SwissData, '/swiss/<int:id>')