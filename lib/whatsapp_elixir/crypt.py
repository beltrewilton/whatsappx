import json
from base64 import b64decode, b64encode
from cryptography.hazmat.primitives.asymmetric.padding import OAEP, MGF1, hashes
from cryptography.hazmat.primitives.ciphers import algorithms, Cipher, modes
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from erlport.erlterms import Atom, Map, List

# {:ok, python} = :python.start_link([{:python_path, ~c"/Users/beltre.wilton/apps/whatsapp_elixir/lib/whatsapp_elixir:/Users/beltre.wilton/miniforge3/envs/tars_env/lib/python3.10/site-packages/cryptography"}, {:python, ~c'python3'}])
# result = :python.call(python, :crypt, :decrypt_request, [data, private_key_pem, passphrase])


def decrypt_request(data: dict, private_key: str, passphrase: str):
    # Read the request fields
    encrypted_flow_data_b64 = data[b'encrypted_flow_data'].decode("utf-8")
    encrypted_aes_key_b64 = data[b'encrypted_aes_key'].decode("utf-8")
    initial_vector_b64 = data[b'initial_vector'].decode("utf-8")


    flow_data = b64decode(encrypted_flow_data_b64)
    iv = b64decode(initial_vector_b64)

    # Decrypt the AES encryption key
    encrypted_aes_key = b64decode(encrypted_aes_key_b64)

    private_key = load_pem_private_key(private_key, password=passphrase)
    aes_key = private_key.decrypt(encrypted_aes_key, OAEP(
        mgf=MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None))

    # Decrypt the Flow data
    encrypted_flow_data_body = flow_data[:-16]
    encrypted_flow_data_tag = flow_data[-16:]
    decryptor = Cipher(algorithms.AES(aes_key),
                       modes.GCM(iv, encrypted_flow_data_tag)).decryptor()
    decrypted_data_bytes = decryptor.update(
        encrypted_flow_data_body) + decryptor.finalize()
    decrypted_data = json.loads(decrypted_data_bytes.decode("utf-8"))
    return decrypted_data, aes_key, iv


def encrypt_response(response: dict, aes_key: str , iv: str):
    print(response)
    response = decode_bytes_in_dict(response)
    

    # Flip the initialization vector
    flipped_iv = bytearray()
    for byte in iv:
        flipped_iv.append(byte ^ 0xFF)

    # Encrypt the response data
    encryptor = Cipher(algorithms.AES(aes_key),
                       modes.GCM(flipped_iv)).encryptor()
    return b64encode(
        encryptor.update(json.dumps(response)) +
        encryptor.finalize() +
        encryptor.tag
    )


def decode_bytes_in_dict(data):
    """
    Recursively decodes all bytes objects in a nested dictionary.

    Args:
        data (dict): The dictionary to decode.

    Returns:
        dict: The dictionary with all bytes objects decoded.
    """
    if isinstance(data, Map):
        print("****** Here a MAP")
        return {key: decode_bytes_in_dict(value) for key, value in data.items()}
    elif isinstance(data, bytes):
        print("****** Here a byte")
        return data.decode("utf-8")
    elif isinstance(data, list):
        print("****** Here a LIST")
        return [decode_bytes_in_dict(item) for item in data]
    else:
        return data