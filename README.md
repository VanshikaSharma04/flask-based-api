# Flask InfluxDB Time Slot Fetcher
This Flask application connects to an InfluxDB database to retrieve time-series data, identifying and grouping consecutive occurrences of a specified value within a given time range into time slots.

### Prerequisites

1. Python 3.x
2. InfluxDB installed and running

### Configuration
Edit the following database parameters in the script if needed:<br>
DB_HOST = "localhost"<br>
DB_PORT = 8086<br>
DB_NAME = "bucket_name"<br>
DB_USER = "user_name"<br>
DB_PASSWORD = "password"<br>

### Steps:
1. Clone the repository:<br>
   git clone https://github.com/yourusername/flask-based-api.git<br>
   cd flask-based-api<br>

2. Install dependencies:<br>
   pip install flask influxdb<br>

3. Run the Flask application:<br>
   python app.py
