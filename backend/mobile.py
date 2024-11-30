from flask import Flask, request, jsonify, send_file
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
import os
import uuid
import time
import requests

# Initialize Flask application
app = Flask(__name__)

# Load environment variables
load_dotenv()

# Fetch the secret key for encryption from .env file
SECRET_KEY = os.getenv('SECRET_KEY')

# Directory to save processed images temporarily
TEMP_DIR = "temp_images"
os.makedirs(TEMP_DIR, exist_ok=True)

# Initialize CryptoSteganography with the secret key
crypto_steganography = CryptoSteganography(SECRET_KEY)

# Define accepted urgency colors
ACCEPTED_COLORS = ['red', 'yellow', 'blue']

# Accepted image formats
ACCEPTED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png']

# Function to get user location based on IP address (using a free API)
def get_user_location():
    try:
        response = requests.get('https://ipinfo.io')
        data = response.json()
        
        location_details = {
            "city": data.get('city', 'Unknown city'),
            "region": data.get('region', 'Unknown region'),
            "country": data.get('country', 'Unknown country'),
            "lat": data.get('loc', 'Unknown location')  # Latitude, longitude
        }
        return location_details
    except Exception as e:
        return "Location not available"

@app.route('/embed', methods=['POST'])
def embed_message():
    try:
        # Parse input data (from form data)
        message = request.form.get('message')  # Get the message from form data
        
        # Set default message if none is provided
        if not message:
            message = 'please help'

        name = request.form.get('name')
        phone = request.form.get('phone')
        urgency_color = request.form.get('urgency_color')
        location = request.form.get('location')
        image_file = request.files.get('image')

        if urgency_color not in ACCEPTED_COLORS:
            return jsonify({"error": f"Invalid urgency color. Accepted colors are: {', '.join(ACCEPTED_COLORS)}"}), 400
        
        location = location or get_user_location()

        if not all([name, phone, urgency_color, location, image_file]):
            return jsonify({"error": "Missing one or more required fields"}), 400

        # Validate image format
        file_extension = image_file.filename.split('.')[-1].lower()
        if file_extension not in ACCEPTED_IMAGE_FORMATS:
            return jsonify({"error": f"Invalid image format. Accepted formats are: {', '.join(ACCEPTED_IMAGE_FORMATS)}"}), 400

        # Open the image
        image = Image.open(image_file)
        
        temp_image_path = None  # To store path of converted image (if any)

        # Convert non-PNG images to PNG
        if file_extension != 'png':
            image = image.convert('RGBA')
            temp_image_path = os.path.join(TEMP_DIR, f"temp_image_{int(time.time())}.png")
            image.save(temp_image_path, format='PNG')
            image = Image.open(temp_image_path)

        # Create the payload
        payload = {
            "message": message,
            "name": name,
            "phone": phone,
            "urgency_color": urgency_color,
            "location": location
        }

        # Convert payload to string
        payload_str = str(payload)

        # Generate a unique filename
        unique_filename = f"embedded_image_{int(time.time())}.png"
        output_path = os.path.join(TEMP_DIR, unique_filename)

        # Embed the message into the image using crypto_steganography
        crypto_steganography.hide(image, output_path, payload_str)
        
        # Cleanup temporary conversion image
        if temp_image_path:
            os.remove(temp_image_path)

        # Send the image as a response
        return send_file(output_path, mimetype='image/png', as_attachment=True)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True,port=5000)