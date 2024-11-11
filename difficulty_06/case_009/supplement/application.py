from flask import Flask, request, jsonify

application = Flask(__name__)

@application.route("/", methods=['POST'])
def process_task():
    data = request.get_json()
    response = {
        "status": "success",
        "data_received": data
    }
    return jsonify(response)

if __name__ == "__main__":
    application.run()
