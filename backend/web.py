from flask import Flask, request, jsonify
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
from pymongo import MongoClient
import os
import json
from flask_cors import CORS
# Initialize Flask application
app = Flask(__name__)
CORS(app)
# Load environment variables
load_dotenv()

# Fetch the secret key and MongoDB URI from .env file
SECRET_KEY = os.getenv('SECRET_KEY')
MONGODB_URI = os.getenv('MONGO_URI')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'steganography_db')
COLLECTION_NAME = os.getenv('COLLECTION_NAME', 'hidden_messages')

# Initialize CryptoSteganography with the secret key
if not SECRET_KEY:
    raise ValueError("SECRET_KEY is not set in the environment variables")
crypto_steganography = CryptoSteganography(SECRET_KEY)

# Initialize MongoDB connection
try:
    client = MongoClient(MONGODB_URI)
    db = client[DATABASE_NAME]
    collection = db[COLLECTION_NAME]
except Exception as e:
    raise Exception(f"Failed to connect to MongoDB: {str(e)}")

@app.route('/extract', methods=['POST'])
def extract_message():
    try:
        # Get the image file from the form
        image_file = request.files.get('image')
        if not image_file:
            return jsonify({"error": "No image file provided"}), 400

        # Open the image
        image = Image.open(image_file)

        # Extract the hidden message from the image
        hidden_message = crypto_steganography.retrieve(image)
        if not hidden_message:
            return jsonify({"error": "No message found in the image"}), 400

        # Debug: Print the hidden message before parsing
        print(f"Hidden message: {hidden_message}")

        # Handle improperly formatted JSON by replacing single quotes with double quotes
        try:
            fixed_message = hidden_message.replace("'", '"')
            message_data = json.loads(fixed_message)
        except json.JSONDecodeError as json_error:
            return jsonify({"error": "Hidden message is not valid JSON", "details": str(json_error)}), 400

        # Prepare the document for MongoDB
        db_data = {
            "message": message_data['message'],
            "name": message_data['name'],
            "phone": message_data['phone'],  # Phone is stored as a separate field
            "urgency_color": message_data['urgency_color'],
            "location": message_data['location']
        }

        # Store the extracted data in MongoDB (MongoDB will generate _id)
        inserted_id = collection.insert_one(db_data).inserted_id

        # Add the _id to the response
        db_data["_id"] = str(inserted_id)

        # Return the stored data
        return jsonify({"message": "Decryption successful", "data": db_data}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Route to fetch all the hidden messages from MongoDB
@app.route('/messages', methods=['GET'])
def get_all_messages():
    try:
        # Fetch all the records from the collection
        messages = list(collection.find())

        # Convert MongoDB _id to string for each document
        for message in messages:
            message['_id'] = str(message['_id'])

        return jsonify(messages), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=7080)
