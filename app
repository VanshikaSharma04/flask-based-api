from flask import Flask, request, jsonify
from influxdb import InfluxDBClient
from datetime import datetime, timedelta

app = Flask(__name__)

DB_HOST = "localhost"
DB_PORT = 8086
DB_NAME = "bucket_name"
DB_USER = "user_name"
DB_PASSWORD = "password"

client = InfluxDBClient(host=DB_HOST, port=DB_PORT, username=DB_USER, password=DB_PASSWORD, database=DB_NAME)

@app.route('/data', methods=['GET'])
def fetch_time_slots():
    """
    Fetch time slots from time series data where a specified value occurs,
    within a given time range.
    """
    try:
        # Parse query parameters
        value = request.args.get('value')
        start_time = request.args.get('startTime')  
        end_time = request.args.get('endTime')      

        if not value or not start_time or not end_time:
            return jsonify({"status": "error", "message": "Missing required parameters: value, startTime, or endTime"}), 400

        # Query the database for the given range and value
        query = f"""
        SELECT time, value
        FROM my_metric
        WHERE value = {value} AND time >= '{start_time}Z' AND time <= '{end_time}Z'
        ORDER BY time ASC
        """
        results = client.query(query)
        points = list(results.get_points())

        # Process points to group consecutive timestamps into time slots
        time_slots = []
        current_slot = None

        for point in points:
            timestamp = datetime.strptime(point['time'], "%Y-%m-%dT%H:%M:%S.%fZ")

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
                current_slot = {"start": timestamp, "end": timestamp}

        # Append the last slot if it exists
        if current_slot:
            duration = int((current_slot["end"] - current_slot["start"]).total_seconds() / 60)
            time_slots.append({
                "start": current_slot["start"].isoformat() + "Z",
                "end": current_slot["end"].isoformat() + "Z",
                "duration": duration
            })

        # Return the response
        return jsonify(time_slots), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True)
