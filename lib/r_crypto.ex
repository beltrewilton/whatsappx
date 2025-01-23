defmodule RCrypto do
  @moduledoc """
  This module contains the NIF function to the rust library.
  """

  use Rustler, otp_app: :whatsapp_flow_crypto, crate: "rcrypto"

  @doc """
  This function fetches the private key from the pem string. The password is optional.
  """
  def fetch_private_key(_private_key_pem, _password), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Decrypts the encrypted AES key encoded as Base64 string using the private reference.
  """
  def decrypt_aes_key(_private_key_ref, _encrypted_aes_key),
    do: :erlang.nif_error(:nif_not_loaded)
end
