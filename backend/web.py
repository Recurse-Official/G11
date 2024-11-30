from flask import Flask, request, jsonify
from cryptosteganography import CryptoSteganography
from PIL import Image
from dotenv import load_dotenv
import os

# Initialize Flask application
app = Flask(__name__)

# Load environment variables
load_dotenv()

# Fetch the secret key for decryption from .env file
SECRET_KEY = os.getenv('SECRET_KEY')

# Initialize CryptoSteganography with the secret key
crypto_steganography = CryptoSteganography(SECRET_KEY)

@app.route('/extract', methods=['POST'])
def extract_message():
    try:
        # Get the image file from the form
        image_file = request.files['image']

        if image_file is None:
            return jsonify({"error": "No image file provided"}), 400

        # Open the image
        image = Image.open(image_file)

        # Extract the hidden message from the image
        hidden_message = crypto_steganography.retrieve(image)

        if hidden_message is None:
            return jsonify({"error": "No message found in the image"}), 400

        # Return the hidden message
        return jsonify({"hidden_message": hidden_message})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True,port=7080)