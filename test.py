import numpy as np
import cv2
from sklearn.decomposition import PCA
from cryptography.fernet import Fernet
import os
from base64 import urlsafe_b64encode, urlsafe_b64decode
from PIL import Image

# Function to generate a key from a password
def generate_key(password):
    password = password.encode('utf-8')  # Convert password to bytes
    return urlsafe_b64encode(password.ljust(32)[:32])  # Ensure key is 32 bytes long

# Function to perform PCA on the image
def apply_pca(image):
    h, w, c = image.shape
    reshaped_image = image.reshape(-1, c)  # Reshape image to (h*w, c) for PCA
    pca = PCA()
    transformed_image = pca.fit_transform(reshaped_image)
    return transformed_image, pca, h, w

# Function to reconstruct the image using PCA
def reconstruct_pca(transformed_image, pca, h, w):
    inverse_transformed_image = pca.inverse_transform(transformed_image)
    reconstructed_image = inverse_transformed_image.reshape(h, w, -1).astype(np.uint8)
    return reconstructed_image

# Function to encrypt data
def encrypt_data(data, key):
    fernet = Fernet(key)
    encrypted_data = fernet.encrypt(data)
    return encrypted_data

# Function to decrypt data
def decrypt_data(encrypted_data, key):
    fernet = Fernet(key)
    decrypted_data = fernet.decrypt(encrypted_data)
    return decrypted_data

# Function to create a test image
def create_test_image(image_path='test_image.png'):
    img = Image.new('RGB', (100, 100), color = 'blue')  # Create a 100x100 blue image
    img.save(image_path)
    print(f"Test image created at {image_path}")

# Main function to process and store image
def process_and_store_image(image_path, password, output_path='encrypted_image.dat'):
    # Read the image
    image = cv2.imread(image_path)
    if image is None:
        raise FileNotFoundError(f"Image not found at path: {image_path}")

    # Apply PCA to reduce size
    transformed_image, pca, h, w = apply_pca(image)

    # Serialize PCA components and image data for storage
    pca_data = {'transformed_image': transformed_image, 'pca_components': pca.components_, 'mean': pca.mean_, 'h': h, 'w': w}
    serialized_data = np.array2string(transformed_image.flatten(), separator=',').encode('utf-8')

    # Generate encryption key from password
    key = generate_key(password)

    # Encrypt the serialized data
    encrypted_data = encrypt_data(serialized_data, key)

    # Save encrypted data to file
    with open(output_path, 'wb') as f:
        f.write(encrypted_data)

    print(f"Image encrypted and stored at {output_path}")

# Function to decrypt and reconstruct image
def decrypt_and_reconstruct_image(input_path, password, output_image_path='decrypted_image.png'):
    # Generate encryption key from password
    key = generate_key(password)

    # Load encrypted data from file
    with open(input_path, 'rb') as f:
        encrypted_data = f.read()

    # Decrypt the data
    decrypted_data = decrypt_data(encrypted_data, key)
    
    # Convert the decrypted data back to numpy array
    decrypted_array = np.fromstring(decrypted_data.decode('utf-8'), sep=',')
    
    # Reshape it back to the original image size using stored dimensions (example assuming this)
    reshaped_image = decrypted_array.reshape((100, 100, -1))  # Example using 100x100 size

    # Save the decrypted image
    cv2.imwrite(output_image_path, reshaped_image)
    print(f"Decrypted image saved at {output_image_path}")

# Example usage
# Create a test image
create_test_image()

# Encrypting and storing the image
process_and_store_image('test_image.png', 'mypassword')

# Decrypting and reconstructing the image
decrypt_and_reconstruct_image('encrypted_image.dat', 'mypassword')
