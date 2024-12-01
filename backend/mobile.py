from flask import Flask, request, jsonify, send_file
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
import os
import time
import json

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
ACCEPTED_COLORS = ['red', 'yellow', 'green']

# Accepted image formats
ACCEPTED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png']

@app.route('/embed', methods=['POST'])
def embed_message():
    try:
        # Check if JSON data is present
        if 'json' not in request.files:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Check if image is present
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400
        
        # Read JSON file
        json_file = request.files['json']
        json_data = json.load(json_file)
        
        # Read image file
        image_file = request.files['image']
        
        # Extract required fields from JSON
        name = json_data.get('name')
        phone_number = json_data.get('phoneNumber')
        message = json_data.get('message')
        urgency_color = json_data.get('urgency_color')
        location = json_data.get('location', {})
        
        # Validate required fields
        if not all([name, phone_number, message, urgency_color, location]):
            return jsonify({"error": "Missing required fields in JSON"}), 400
        
        # Validate urgency color
        if urgency_color not in ACCEPTED_COLORS:
            return jsonify({"error": f"Invalid urgency color. Accepted colors are: {', '.join(ACCEPTED_COLORS)}"}), 400
        
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
            "phone": phone_number,
            "urgency_color": urgency_color,
            "location": {
                "latitude": location.get('latitude', 'Unknown'),
                "longitude": location.get('longitude', 'Unknown')
            }
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
        
        # Send the embedded image as a response
        return send_file(output_path, mimetype='image/png', as_attachment=True)
    
    except json.JSONDecodeError:
        return jsonify({"error": "Invalid JSON format"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0",debug=True, port=5050)