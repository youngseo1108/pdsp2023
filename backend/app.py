# from flask import Flask, request, jsonify

# app = Flask(__name__)

# @app.route('/get_sum', methods=['GET']) 
# def get_sum():
#     x = request.args.get('x')
#     y = request.args.get('y')
#     result = int(x) + int(y)
                     
#     return '{}'.format(result)

# if __name__ == '__main__':
#     app.run(host='0.0.0.0', port = 5000, debug = True)
import psycopg2
from flask import Flask, render_template
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# Replace the 'postgresql://username:password@localhost/dbname' with your PostgreSQL connection string.
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:1108@localhost/preprocess'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False  # Avoids a warning message

db = SQLAlchemy(app)

# Define a simple model
class ItineraryInput(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    # username = db.Column(db.String(80), unique=True, nullable=False)

    def __repr__(self):
        return f'<ItineraryInput {self.id}>'

def get_db_connection():
    conn = psycopg2.connect(host='localhost',
                            database='preprocess',
                            user='postgres',
                            password='1108')
    return conn

@app.route('/')
def index():
    # conn = get_db_connection()
    # cur = conn.cursor()
    # cur.execute('SELECT * FROM itinerary_input;')
    # books = cur.fetchall()
    # cur.close()
    # conn.close()
    itinerary_inputs = ItineraryInput.query.all()
    return render_template('index.html', itinerary_inputs=itinerary_inputs)

if __name__ == '__main__':
    # Move db.create_all() inside the conditional block
    with app.app_context():
        db.create_all()
    
    app.run(debug=True)