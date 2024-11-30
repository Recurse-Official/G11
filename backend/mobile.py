from flask import Flask, request, jsonify, send_file
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
import os
import uuid  # Import UUID for unique file naming
import time  # Alternative: for timestamp-based naming
import requests


app = Flask(__name__)

load_dotenv()

# Secret key for encryption (this can be stored securely in env variables)
# SECRET_KEY = "my_secure_key"
SECRET_KEY = os.getenv('SECRET_KEY')


# Directory to save processed images temporarily
TEMP_DIR = "temp_images"
os.makedirs(TEMP_DIR, exist_ok=True)

# Initialize CryptoSteganography
crypto_steganography = CryptoSteganography(SECRET_KEY)

# Define the accepted urgency colors (only red, green, and blue)
ACCEPTED_COLORS = ['red', 'yellow', 'blue']

# Accepted input image formats
ACCEPTED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png']

# Function to get user location based on IP address (using a free API)
def get_user_location():
    try:
        # Use a free geolocation API to get the user's location
        response = requests.get('https://ipinfo.io')
        data = response.json()
        # return data.get('city', 'Unknown location')  # Return city, or default to 'Unknown location'
        
        # Get the location details (city, region, country, and the location as latitude and longitude)
        location_details = {
            "city": data.get('city', 'Unknown city'),
            "region": data.get('region', 'Unknown region'),
            "country": data.get('country', 'Unknown country'),
            "location": data.get('loc', 'Unknown location')  # Returns 'latitude,longitude'
        }
        return location_details  # Returning the detailed location information
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
        
        # Check if the urgency_color is valid
        if urgency_color not in ACCEPTED_COLORS:
            return jsonify({"error": f"Invalid urgency color. Accepted colors are: {', '.join(ACCEPTED_COLORS)}"}), 400
        
        # # If location is not provided, try to auto-detect it
        # if not location:
        #     location = get_user_location()
        
        # If location is not provided, try to auto-detect it
        location = location or get_user_location()  # Fallback to auto-detected location if not provided

        if not all([name, phone, urgency_color, location, image_file]):
            return jsonify({"error": "Missing one or more required fields"}), 400


        # Validate input image format
        file_extension = image_file.filename.split('.')[-1].lower()
        if file_extension not in ACCEPTED_IMAGE_FORMATS:
            return jsonify({"error": f"Invalid image format. Accepted formats are: {', '.join(ACCEPTED_IMAGE_FORMATS)}"}), 400
        
        # Open the provided image
        image = Image.open(image_file)
        
        # Convert non-PNG images to PNG
        if file_extension != 'png':
            image = image.convert('RGBA')  # Convert to RGBA for compatibility
            temp_image_path = os.path.join(TEMP_DIR, f"temp_image_{int(time.time())}.png")
            image.save(temp_image_path, format='PNG')
            image = Image.open(temp_image_path)  # Reload as PNG

        # Create the data package
        payload = {
            "message": message,
            "name": name,
            "phone": phone,
            "urgency_color": urgency_color,
            "location": location  # Can be a structured location or fallback string
        }

        # Convert payload to string
        payload_str = str(payload)

        # Path to save the output image
        # output_path = os.path.join(TEMP_DIR, "embedded_image.png")
        
        # Generate a unique filename
        # unique_filename = f"embedded_image_{uuid.uuid4().hex}.png"
        # Alternatively, use timestamp:
        unique_filename = f"embedded_image_{int(time.time())}.png"
        
        # Path to save the output image
        output_path = os.path.join(TEMP_DIR, unique_filename)

        # Embed the encrypted message into the image
        crypto_steganography.hide(image, output_path, payload_str)

        # Send the image as a response
        return send_file(output_path, mimetype='image/png', as_attachment=True)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/extract', methods=['POST'])
def extract_message():
    try:
        # Get the image file
        image_file = request.files['image']

        if image_file is None:
            return jsonify({"error": "No image file provided"}), 400

        # Open the image
        image = Image.open(image_file)

        # Extract the hidden message
        hidden_message = crypto_steganography.retrieve(image)

        if hidden_message is None:
            return jsonify({"error": "No message found in the image"}), 400

        return jsonify({"hidden_message": hidden_message})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True)
