defmodule WhatsappElixir.Flow do
  @moduledoc """
  Module to handle WhatsApp flow.
  """

  require Logger
  alias WhatsappElixir.HTTP
  alias WhatsappElixir.Static

  @endpoint "messages"

  def send_flow_as_message(to, data, custom_config \\ [], opts \\ []) do
    template_name = Keyword.get(opts, :template_name)
    image_link = Keyword.get(opts, :image_link)
    screen = Keyword.get(opts, :screen)

    payload = %{
      "recipient_type" => "individual",
      "messaging_product" => "whatsapp",
      "to" => to,
      "type" => "template",
      "template" => %{
        "name" => template_name,
        "language" => %{
          "code" => "en"
        },
        "components" => [
          %{
            "type" => "header",
            "parameters" => [
              %{
                "type" => "image",
                "image" => %{
                  "link" => image_link
                }
              }
            ]
          },
          %{
            "type" => "button",
            "sub_type" => "flow",
            "index" => "0",
            "parameters" => [
              %{
                "type" => "action",
                "action" => %{
                  "flow_token" => UUID.uuid4(),
                  "flow_action_data" => data
                }
              }
            ]
          }
        ]
      }
    }

    IO.inspect(payload, label: "Payload")

    Logger.info("Sending flow to #{to}")

    case HTTP.post(@endpoint, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Flow sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Flow not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def send_flow(to, data, custom_config \\ [], opts \\ []) do
    flow_id = Keyword.get(opts, :flow_id)
    cta = Keyword.get(opts, :cta)
    screen = Keyword.get(opts, :screen)

    header = Keyword.get(opts, :header, "Flow message header")
    body = Keyword.get(opts, :body, "Flow message body")
    footer = Keyword.get(opts, :footer, "Flow message footer")
    mode = Keyword.get(opts, :mode)

    payload = %{
      "recipient_type" => "individual",
      "messaging_product" => "whatsapp",
      "to" => to,
      "type" => "interactive",
      "interactive" => %{
        "type" => "flow",
        "header" => %{
          "type" => "text",
          "text" => header
        },
        "body" => %{
          "text" => body
        },
        "footer" => %{
          "text" => footer
        },
        "action" => %{
          "name" => "flow",
          "parameters" => %{
            "mode" => mode,
            "flow_message_version" => "3",
            "flow_token" => UUID.uuid4(),
            "flow_id" => flow_id,
            "flow_cta" => cta,
            "flow_action" => "navigate",
            "flow_action_payload" => %{
              "screen" => screen,
              "data" => data
            }
          }
        }
      }
    }

    Logger.info("Sending flow to #{to}")

    case HTTP.post(@endpoint, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Flow sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Flow not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def decrypt(data, private_key_pem, passphrase) do
    encrypted_flow_data = data["encrypted_flow_data"]
    encrypted_aes_key = data["encrypted_aes_key"]
    initial_vector = data["initial_vector"]

    {:ok, ref} = WhatsappFlowCrypto.fetch_private_key(private_key_pem)

    {:ok, {result, aes_key, iv}} =
      WhatsappFlowCrypto.decrypt_request(
        ref,
        encrypted_aes_key,
        initial_vector,
        encrypted_flow_data
      )

    {:ok, {result, aes_key, iv}}
  end

  def encrypt(response, aes_key, iv) do
    WhatsappFlowCrypto.encrypt_response(aes_key, iv, response)
  end
end
