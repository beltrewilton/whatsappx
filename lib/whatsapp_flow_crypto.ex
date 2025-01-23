defmodule WhatsappFlowCrypto do
  @moduledoc """
  Load the private key from the file system. The private key is reused once loaded. The library returns a reference
    to the private key. This can be done by the function `fetch_private_key/2`. Just read the private key and
    call the function to receive a reference of the private key. If the private key is encrypted you need to
    specify the password.

  For each request, we do the encryption like this:
    1. Decrypt the encrypted AES key
    2. Decrypt the request with initial vector and the encrypted AES key
    3. Encrypt the response with the inverted initial vector and the encrypted AES key


      {:ok, private_key_pem} = File.read(private_pem_path);
      WhatsappFlowCrypto.fetch_private_key(private_key_pem, "test")
      {:ok, #Reference<0.1652491651.443678740.227250>}

  After this, you can decrypt the request. The request contains
    * the encrypted AES key
    * the initial vector
    * the encrypted flow data

  All values are base64 encoded.
      WhatsappFlowCrypto.decrypt_request(private_key_ref, encrypted_aes_key, initial_vector, encrypted_flow_data)
      {:ok, {decrypted_body, aes_key, initial_vector}}

      WhatsappFlowCrypto.encrypt_response(aes_key, initial_vector, response)
      "KUkRnUDAUKqhiovnQ9RRwmdBjcg87/wh+ZrMtbh8xlx3"
  """

  import Bitwise

  @tag_length 16

  @doc """
  Fetches the private key from the pem. The password is optional and only needed if the
    private key is encrypted. Heads up: some cipher are not supported by this library. The DES3 cipher
    is unsupported. You can use another cipher (AES-128) to encrypt the private key.
  """
  def fetch_private_key(pem, password \\ nil) do
    RCrypto.fetch_private_key(pem, password)
  end

  @doc """
  Decrypts the encrypted body and AES key using the private key reference. It returns the decrypted JSON map, the decrypted AES key and the initial vector.
  They are need to decrypt the response.
  """
  def decrypt_request(private_key_ref, encrypted_aes_key, initial_vector, encrypted_flow_data) do
    with {:ok, aes_key} <- RCrypto.decrypt_aes_key(private_key_ref, encrypted_aes_key),
         {:ok, initial_vector} <- Base.decode64(initial_vector),
         {:ok, encrypted_flow_data} <- Base.decode64(encrypted_flow_data) do
      data_size = byte_size(encrypted_flow_data) - @tag_length

      <<encrypted_flow_data_body::binary-size(data_size),
        encrypted_flow_data_tag::binary-size(@tag_length)>> = encrypted_flow_data

      decrypted_body =
        :aes_128_gcm
        |> :crypto.crypto_one_time_aead(
          aes_key,
          initial_vector,
          encrypted_flow_data_body,
          "",
          encrypted_flow_data_tag,
          false
        )
        |> Jason.decode!()

      {:ok, {decrypted_body, aes_key, initial_vector}}
    end
  end

  @doc """
  Encrypts the response using the decrypted_aes_key and initial vector of the request. The response will be encoded as JSON.
  """
  def encrypt_response(decrypted_aes_key, initial_vector, response) do
    response =
      response
      |> Jason.encode!()
      |> IO.iodata_to_binary()

    initial_vector = flip_initial_vector(initial_vector)

    {encrypted_flow_data_body, tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        decrypted_aes_key,
        initial_vector,
        response,
        "",
        @tag_length,
        true
      )

    Base.encode64(<<encrypted_flow_data_body::binary, tag::binary>>)
  end

  defp flip_initial_vector(iv) do
    flip_initial_vector(iv, [])
  end

  defp flip_initial_vector(<<>>, acc) do
    acc
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp flip_initial_vector(<<a::8, rest::binary>>, acc) do
    flip_initial_vector(rest, [<<(~~~a)>> | acc])
  end
end
