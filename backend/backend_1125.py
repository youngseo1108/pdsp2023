from flask import Flask, render_template
from flask import jsonify
from flask import request
import psycopg2
#from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)     #create a flask instance
#app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:0000@localhost/preprocess'
#app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False  # Avoids a warning message

#db = SQLAlchemy(app)   #call database

# define connection
# note change to Cloud SQL server later
def get_db_connection():
    conn = psycopg2.connect(
        host='35.228.34.114',
        user = 'postgres',
        password = 'P@ssw0rd!',
        database = 'postgres',  # the name of the batabase we are connecting
        port = "5432")
    return conn

# Explain:
# Flask routes: respond to AJAX requests from the frontend.
# # Each route will query the PostgreSQL database and return the necessary data in JSON format.

# 1: Itinerary Input Component
# Route to get unique departure days
# Expect: return a line 1,2,3,4,5,6,7
@app.route('/get_depDay')
def get_departure_days():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT DISTINCT "depDay" FROM itinerary_input;')
    days = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify([day[0] for day in days])

# Route to get unique origin countries
#Expect: return a line of original country name
@app.route('/get_Orig_s')
def get_Orig_s():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT DISTINCT "Orig_s" FROM itinerary_input;')
    origins = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify([origin[0] for origin in origins])

# Route to get destination countries based on selected origin
# Expect: return a line of dest country name given orig country
@app.route('/get_Dest_s/<origin>')
def get_Dest_s(origin):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT DISTINCT "Dest_s" FROM itinerary_input WHERE "Orig_s" =%s', (origin,))
    # Orig_s = %s: filters the results
    destinations = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify([destination[0] for destination in destinations])

# 2: Map Component
# based on the orig, dest input info from itinerary_input_component
# Expect: return one country
@app.route('/get_map_orig', methods=['GET'])
def get_map_orig():
    # Extract query parameters
    orig_s = request.args.get('Orig_s')

    # Get database connection
    conn = get_db_connection()
    cursor = conn.cursor()

    # Prepare SQL query using safe parameterized statements
    # The exact JOIN condition will depend on how these two tables are related.
    # Below is a hypothetical example. You need to adjust the ON condition based on your schema.
    query = """
    SELECT DISTINCT m."Orig_s"
    FROM map m
    JOIN itinerary_input ii ON m.itinerary_input_id = ii.id      
    WHERE ii."Orig_s" = %s ;
    """
    cursor.execute(query, (orig_s,))

    # Fetch the result
    result = cursor.fetchone()
    cursor.close()
    conn.close()

    # Check if we got a result
    if result:
        return jsonify(result)
    else:
        return jsonify({'error': 'No data found'}), 404
# test SQL:
#SELECT DISTINCT m."Orig_s"
#    FROM map m
#    JOIN itinerary_input ii ON m.itinerary_input_id = ii.id
#    WHERE ii."Orig_s" = 'DE'

@app.route('/get_map_dest', methods=['GET'])
def get_map_dest():
    # Extract query parameters
    dest_s = request.args.get('Dest_s')

    # Get database connection
    conn = get_db_connection()
    cursor = conn.cursor()

    # Prepare SQL query using safe parameterized statements
    # The exact JOIN condition will depend on how these two tables are related.
    query = """
    SELECT DISTINCT m."Dest_s"
    FROM map m
    JOIN itinerary_input ii ON m.itinerary_input_id = ii.id      
    WHERE ii."Dest_s" = %s ;
    """
    cursor.execute(query, (dest_s,))

    # Fetch the result
    result = cursor.fetchone()
    cursor.close()
    conn.close()

    # Check if we got a result
    if result:
        return jsonify(result)
    else:
        return jsonify({'error': 'No data found'}), 404

# 3: Market Share Pie Component
# now it's based on user input info of orig and dest
# Expect: return a line of market_share value
@app.route('/get_market_share', methods=['GET'])
def get_market_share():
    # Extract query parameters
    orig_s = request.args.get('Orig_s')
    dest_s = request.args.get('Dest_s')

    # Get database connection
    conn = get_db_connection()
    cursor = conn.cursor()

    # Prepare SQL query using safe parameterized statements
    # The exact JOIN condition will depend on how these two tables are related.
    # Note: Orig_s =%s, Dest_s=%s
    query = """
    SELECT ms.market_share
    FROM marketshare ms
    JOIN itinerary_input ii ON ms.itinerary_input_id = ii.id      
    WHERE ii."Orig_s" = %s AND ii."Dest_s" = %s;
    """
    cursor.execute(query, (orig_s, dest_s))

    # Fetch the result
    results = cursor.fetchall()
    #result = cursor.fetchone()
    cursor.close()
    conn.close()

    return jsonify([result[0] for result in results])

    # Check if we got a result
    #if result:
        #return jsonify({'market_share': result[0]})
    #else:
        #return jsonify({'error': 'No data found'}), 404

# test SQL
# SELECT ms.market_share
#     FROM marketshare ms
#     JOIN itinerary_input ii ON ms.itinerary_input_id = ii.id
#     WHERE ii."Orig_s" = 'DE' AND ii."Dest_s" = 'US';

# 4. Recommendation Component
#Expect: get lines of info
@app.route('/get_recommendation', methods=['GET'])
def get_recommendation():
    orig_s = request.args.get('Orig_s')
    dest_s = request.args.get('Dest_s')

    conn = get_db_connection()
    cursor = conn.cursor()
# create temporary result --> ranked_options
# Note: consider m."id" = ii."id"

    query = """
    WITH ranked_options AS (
    SELECT
        r."dep_hour",
        r."arr_hour",
        r."elaptime",
        r."option",
        m."market_share",
        RANK() OVER (ORDER BY m."market_share" DESC) as rank
    FROM
        recommendation r
    JOIN itinerary_input ii ON r."itinerary_input_id" = ii."id"
    JOIN marketshare m ON r."id" = m."id"
    WHERE
        ii."Orig_s" = %s AND ii."Dest_s" = %s
    )
    SELECT
      "dep_hour",
      "arr_hour",
      "elaptime",
      CASE
        WHEN rank <= 3 THEN 'Create'
        ELSE 'Cancel'
      END as "option"
    FROM
      ranked_options
    ;
    """

    cursor.execute(query, (orig_s, dest_s))
    recommendations = cursor.fetchall()

    cursor.close()
    conn.close()

    # Structure the results as a JSON array of objects
    recommendations_data = [
        {'Dephours': dep_hour, 'Arrhours': arr_hour, 'Elptime': elaptime, 'Option': option}
        for dep_hour, arr_hour, elaptime, option in recommendations
    ]

    return jsonify(recommendations_data)
# test SQL:
# WITH ranked_options AS (
#     SELECT
#         r."dep_hour",
#         r."arr_hour",
#         r."elaptime",
#         r."option",
#         m."market_share",
#         RANK() OVER (ORDER BY m."market_share" DESC) as rank
#     FROM
#         recommendation r
#     JOIN itinerary_input ii ON r."itinerary_input_id" = ii."id"
#     JOIN marketshare m ON r."id" = m."id"
#     WHERE
#         ii."Orig_s" = 'DE' AND ii."Dest_s" = 'SA'
# )
# SELECT
#     "dep_hour",
#     "arr_hour",
#     "elaptime",
# 	"market_share"
# FROM
#     ranked_options
# ;

# 5: Result Component
# given itinerary_input and market_share ranking
@app.route('/results', methods=['GET'])
def get_results():
    orig_s = request.args.get('Orig_s')
    dest_s = request.args.get('Dest_s')

    conn = get_db_connection()
    cursor = conn.cursor()
    # WHERE
    # i."Orig_s" = %s AND i."Dest_s" = %s
    query = """
        SELECT r."TOT_pax", r."accuracy"
        FROM result r
        INNER JOIN marketshare m ON r."marketshare_id" = m."id"
        INNER JOIN itinerary_input i ON r."id" = i."id"
        WHERE i."Orig_s" = 'DE' AND i."Dest_s" = 'UAE'
        ORDER BY m."market_share" DESC
        LIMIT 1;
        """

    cursor.execute(query, (orig_s, dest_s))
    result = cursor.fetchall()

    cursor.close()
    conn.close()

    # Structure the results as a JSON array of objects
    result_data = [
        {'TOT_pax': TOT_pax, 'Accuracy': accuracy}
        for TOT_pax, accuracy in result
    ]

    return jsonify(result_data)


# test SQL:
# SELECT r."TOT_pax", r."accuracy", m."market_share"
#     FROM result r
#     INNER JOIN marketshare m ON r."marketshare_id" = m."id"
#     INNER JOIN itinerary_input i ON r."id" = i."id"
#     WHERE i."Orig_s" = 'DE' AND i."Dest_s" = 'OM'
#     ORDER BY m."market_share" DESC
#     LIMIT 1


# 6: Other Info Component
# 1) given itinerary_input
# 2) market_share ranking-->show the 1st info
@app.route('/other', methods=['GET'])
def get_other():
    orig_s = request.args.get('Orig_s')
    dest_s = request.args.get('Dest_s')

    conn = get_db_connection()
    cursor = conn.cursor()
    # WHERE
    # i."Orig_s" = %s AND i."Dest_s" = %s
    query = """
        SELECT o."detour", o."stops", o."real_dist"
        FROM other_info o
        INNER JOIN marketshare m ON o."marketshare_id" = m."id"
        INNER JOIN itinerary_input i ON o."id" = i."id"
        WHERE i."Orig_s" = %s AND i."Dest_s" = %s
        ORDER BY m."market_share" DESC
        LIMIT 1;
        """

    cursor.execute(query, (orig_s, dest_s))
    recommendations = cursor.fetchall()

    cursor.close()
    conn.close()

    # Structure the results as a JSON array of objects
    other_data = [
        {'Detour': detour, 'Stops': stops, 'Distance': real_dist}
        for detour, stops, real_dist in recommendations
    ]

    return jsonify(other_data)


if __name__ == '__main__':
    app.run(debug=True)