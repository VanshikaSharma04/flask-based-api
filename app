from flask import Flask, request, jsonify
from influxdb import InfluxDBClient
from datetime import datetime, timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

app = Flask(__name__)

DB_HOST = "localhost"
DB_PORT = 8086
DB_NAME = "bucket_new"
DB_USER = "Vanshika"
DB_PASSWORD = "Australia@123"

logging.info("Connecting to InfluxDB...")
client = InfluxDBClient(host=DB_HOST, port=DB_PORT, username=DB_USER, password=DB_PASSWORD, database=DB_NAME)
logging.info("Connected to InfluxDB successfully")

@app.route('/data', methods=['GET'])
def fetch_time_slots():
    """
    Fetch time slots from time series data where a specified value occurs,
    within a given time range.
    """
    try:
        logging.debug("Received request to fetch time slots")
        
        # Parse query parameters
        value = request.args.get('value')
        start_time = request.args.get('startTime')  
        end_time = request.args.get('endTime')      

        if not value or not start_time or not end_time:
            logging.warning("Missing required parameters: value, startTime, or endTime")
            return jsonify({"status": "error", "message": "Missing required parameters: value, startTime, or endTime"}), 400

        logging.debug(f"Query parameters - value: {value}, startTime: {start_time}, endTime: {end_time}")

        # Query the database for the given range and value
        query = f"""
        SELECT time, value
        FROM my_metric
        WHERE value = {value} AND time >= '{start_time}Z' AND time <= '{end_time}Z'
        ORDER BY time ASC
        """
        
        logging.debug(f"Executing query: {query}")
        results = client.query(query)
        points = list(results.get_points())
        logging.info(f"Query executed successfully. Retrieved {len(points)} points.")

        # Process points to group consecutive timestamps into time slots
        time_slots = []
        current_slot = None

        for point in points:
            timestamp = datetime.strptime(point['time'], "%Y-%m-%dT%H:%M:%S.%fZ")
            logging.debug(f"Processing timestamp: {timestamp}")

            if current_slot is None:
                current_slot = {"start": timestamp, "end": timestamp}
            elif (timestamp - current_slot["end"]).seconds <= 60:  # Extend the slot if within 1 minute
                current_slot["end"] = timestamp
            else:
                # Finalize the current slot
                duration = int((current_slot["end"] - current_slot["start"]).total_seconds() / 60)
                time_slots.append({
                    "start": current_slot["start"].isoformat() + "Z",
                    "end": current_slot["end"].isoformat() + "Z",
                    "duration": duration
                })
                logging.debug(f"Added time slot: {time_slots[-1]}")
                current_slot = {"start": timestamp, "end": timestamp}

        # Append the last slot if it exists
        if current_slot:
            duration = int((current_slot["end"] - current_slot["start"]).total_seconds() / 60)
            time_slots.append({
                "start": current_slot["start"].isoformat() + "Z",
                "end": current_slot["end"].isoformat() + "Z",
                "duration": duration
            })
            logging.debug(f"Added final time slot: {time_slots[-1]}")

        # Return the response
        logging.info("Returning response with time slots")
        return jsonify(time_slots), 200

    except Exception as e:
        logging.error(f"Error occurred: {str(e)}", exc_info=True)
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    logging.info("Starting Flask application...")
    app.run(debug=True)
