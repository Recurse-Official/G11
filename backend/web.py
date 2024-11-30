from flask import Flask, request, jsonify
from pymongo import MongoClient
from datetime import datetime, timezone
from dotenv import load_dotenv
import os
app = Flask(__name__)

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
# MongoDB configuration
client = MongoClient("MONGO_URI") 
db = client["steganography_db"] 
collection = db["user_messages"] 

@app.route('/upload', methods=['POST'])
def upload_message():
    try:
        data = request.json 
        document = {
            "name": data.get("name"),
            "location": data.get("location"),
            "colour":data.get("colour"),
            "message": data.get("color_message"),
            "phone": data.get("phone", None), 
            "timestamp": datetime.now(timezone.utc)
        }
        result = collection.insert_one(document)
        return jsonify({"success": True, "inserted_id": str(result.inserted_id)}), 201
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
