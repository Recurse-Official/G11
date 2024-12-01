from flask import Flask, request, jsonify, send_file
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
from pymongo import MongoClient
import os
import time
import json

# Initialize Flask application
app = Flask(__name__)

# Load environment variables
load_dotenv()

# Fetch the secret key for encryption from .env file
SECRET_KEY = os.getenv('SECRET_KEY')
EMERGENCY_PIN = os.getenv('EMERGENCY_PIN')
MONGO_URI = os.getenv('MONGO_URI')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'steganography_db')
COLLECTION_NAME = os.getenv('COLLECTION_NAME', 'hidden_messages')

# Initialize MongoDB client
client = MongoClient(MONGO_URI)
db = client[DATABASE_NAME]
collection = db[COLLECTION_NAME]

# Directory to save processed images temporarily
TEMP_DIR = "temp_images"
os.makedirs(TEMP_DIR, exist_ok=True)

# Initialize CryptoSteganography with the secret key
crypto_steganography = CryptoSteganography(SECRET_KEY)

# Rest of your existing code remains the same...

@app.route('/emergency_pin', methods=['POST'])
def emergency_pin():
    try:
        # Get PIN and check if it's the emergency PIN
        pin = request.json.get("pin")
        
        if pin != EMERGENCY_PIN:
            return jsonify({"error": "Invalid PIN"}), 400
        
        # Fetch data from the request
        name = request.json.get('name')
        phone_number = request.json.get('phoneNumber')
        message = request.json.get('message')
        urgency_color = request.json.get('urgency_color')
        location = request.json.get('location', {})
        
        # Validate required fields
        if not all([name, phone_number, message, urgency_color, location]):
            return jsonify({"error": "Missing required fields"}), 400
        
        # Store emergency data into MongoDB
        emergency_data = {
            "name": name,
            "phone": phone_number,
            "message": message,
            "urgency_color": urgency_color,
            "location": location,
            "timestamp": time.time()
        }
        
        # Insert the emergency data into the hidden_messages collection
        collection.insert_one(emergency_data)
        
        # Return success message
        return jsonify({"message": "Emergency data saved successfully"}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True, port=5050)