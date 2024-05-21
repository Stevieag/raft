# print_timestamp.py
from prometheus_flask_exporter import PrometheusMetrics
from flask import Flask, jsonify
import time

app = Flask(__name__)
metrics = PrometheusMetrics(app) 

@app.route('/timestamp', methods=['GET'])
def get_timestamp():
    ts = time.time()
    return jsonify({'timestamp': ts})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4430)

