defmodule WhatsappElixir.Messages do
  @moduledoc """
  Module to handle WhatsApp messaging.
  """

  require Logger
  alias WhatsappElixir.HTTP
  alias WhatsappElixir.Static

  @endpoint "messages"
  @oauth_endpoint "oauth/access_token"
  @endpoint_subscribed_apps "subscribed_apps"
  @endpoint_register_cust_ph "register"
  @endpoint_smb_app_data_sync "smb_app_data"
  @endpoint_media "media"
  @phone_numbers "phone_numbers"
  @conversational_automation "conversational_automation"

  def get_config() do
    [
      token: System.get_env("CLOUD_API_TOKEN"),
      phone_number_id: System.get_env("CLOUD_API_PHONE_NUMBER_ID"),
      verify_token: System.get_env("CLOUD_API_TOKEN_VERIFY"),
      base_url: "https://graph.facebook.com",
      api_version: "v22.0"
    ]
  end

  @doc """
    ## Parameters

    - `template`: The name of the template to be sent.
    - `recipient_id`: The recipient's WhatsApp ID.
    - `components`: A list of components (e.g., buttons, text) to include in the template message.
    - `lang`: (Optional) The language code for the message. Defaults to `"en_US"`.
    - `custom_config`: (Optional) A list of custom configuration options for the HTTP request.

  ## Examples

      iex> send_template("hello_world", "+2547111111111""}])
      {:ok, %{"status" => "sent"}}

      iex> send_template("welcome_template", "+2547111111111"", [], "fr_FR" , custom_configs)
      {:ok, %{"status" => "sent"}}

  ## Returns

    - `{:ok, response}`: On success, returns `:ok` and the HTTP response.
    - `{:error, response}`: On failure, returns `:error` and the HTTP response.

  """
  def send_template(
        template,
        phone_number_id,
        recipient_id,
        components,
        lang \\ "en_US",
        custom_config \\ []
      ) do
    data = %{
      "messaging_product" => "whatsapp",
      "to" => recipient_id,
      "type" => "template",
      "template" => %{
        "name" => template,
        "language" => %{"code" => lang},
        "components" => components
      }
    }

    Logger.info("Sending template to #{recipient_id}")

    case HTTP.post(@endpoint, phone_number_id, data, custom_config) do
      {:ok, response} ->
        Logger.info("Template sent to #{recipient_id}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Template not sent to #{recipient_id}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def test_it() do
    Logger.info("Test it!")
  end

  def oauth_access_token(code) do
    client_secret = System.get_env("META_APP_SECRET")
    client_id = System.get_env("META_APP_ID")

    params = [
      {"client_id", client_id},
      {"client_secret", client_secret},
      {"code", code}
    ]

    IO.inspect(params, label: "oauth_access_token params")

    case HTTP.get_no_header(@oauth_endpoint, params, get_config()) do
      {:ok, response} ->
        Logger.info("oauth_access_token success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("oauth_access_token fail!")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def subscribed_apps(access_token, waba_id, tenant) do
    verify_token = System.get_env("CLOUD_API_TOKEN_VERIFY")

    body = %{
      # "override_callback_uri" => "https://flwebhook.loophole.site/#{tenant}",
      "override_callback_uri" => "https://flwebhook.loca.lt/#{tenant}",
      "verify_token" => verify_token
    }
    
    IO.inspect(body, label: "override_callback_uri")

    case HTTP.post_subscribed_apps(
           @endpoint_subscribed_apps,
           body,
           access_token,
           waba_id,
           get_config()
         ) do
      {:ok, response} ->
        Logger.info("subscribed_apps success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("Error Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def get_subscribed_apps(access_token, waba_id) do
    case HTTP.get_subscribed_apps(
           @endpoint_subscribed_apps,
           access_token,
           waba_id,
           get_config()
         ) do
      {:ok, response} ->
        Logger.info("subscribed_apps success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("Error Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def delete_subscribed_apps(access_token, waba_id) do
    case HTTP.delete_subscribed_apps(
           @endpoint_subscribed_apps,
           access_token,
           waba_id,
           get_config()
         ) do
      {:ok, response} ->
        Logger.info("subscribed_apps success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("Error Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def register_cust_ph(access_token, phone_number_id) do
    body = %{
      "messaging_product" => "whatsapp",
      "pin" => "777777"
    }

    case HTTP.post_register_cust_ph(
           @endpoint_register_cust_ph,
           access_token,
           phone_number_id,
           body,
           get_config()
         ) do
      {:ok, response} ->
        Logger.info("register_cust_ph success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("Error Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def fetch_phone_numbers(access_token, waba_id) do
    app_config = [
      waba_id: waba_id
    ]

    app_config = Keyword.merge(get_config(), Keyword.merge(get_config(), app_config))

    params = [
      {"fields",
       "id,cc,country_dial_code,display_phone_number,verified_name,status,quality_rating,search_visibility,platform_type,code_verification_status"},
      {"access_token", access_token}
    ]

    IO.inspect(params, label: "fetch_phone_numbers params")

    case HTTP.get_no_header(@phone_numbers, params, app_config, waba_id) do
      {:ok, response} ->
        Logger.info("fetch_phone_numbers success!")
        {:ok, response}

      {:error, response} ->
        Logger.error("fetch_phone_numbers fail!")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end
  
  
  def synchronization(access_token, phone_number_id, sync_type \\ "smb_app_state_sync") do
    body = %{
      "messaging_product" => "whatsapp",
      "sync_type" => sync_type
    }

    case HTTP.post_register_cust_ph(
           @endpoint_smb_app_data_sync,
           access_token,
           phone_number_id,
           body,
           get_config()
         ) do
      {:ok, response} ->
        Logger.info("smb_app_data_sync success!")
        {:ok, Jason.decode!(response)}

      {:error, response} ->
        Logger.error("Error Response: #{inspect(response)}")
        {:error, response}
    end
  end

  @doc """
  Marks a message as read.
  """
  def mark_as_read(message_id, phone_number_id, custom_config \\ []) do
    payload = %{
      "messaging_product" => "whatsapp",
      "status" => "read",
      "message_id" => message_id,
      "typing_indicator" => %{
          "type" => "text"
        }
    }

    case HTTP.post(@endpoint, phone_number_id, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Message marked as read: #{inspect(response)}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Failed to mark message as read: #{inspect(response)}")
        {:error, response}
    end
  end
  
  
  def conversational_automation(prompts, phone_number_id, custom_config \\ []) do
    payload = %{
      "enable_welcome_message" => "true",
      "prompts" => prompts
    }

    case HTTP.post(@conversational_automation, phone_number_id, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Message conversational_automation: #{inspect(response)}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Failed conversational_automation: #{inspect(response)}")
        {:error, response}
    end
  end

  @doc """
  Replies to a message with a given text.
  """
  def reply(data, phone_number_id, reply_text \\ "", custom_config \\ [], preview_url \\ true) do
    author = get_author(data)

    payload = %{
      "messaging_product" => "whatsapp",
      "recipient_type" => "individual",
      "to" => author,
      "type" => "text",
      "context" => %{"message_id" => get_message_id(data)},
      "text" => %{"preview_url" => preview_url, "body" => reply_text}
    }

    Logger.info("Replying to #{get_message_id(data)}")

    case HTTP.post(@endpoint, phone_number_id, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Message sent to #{author}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Message not sent to #{author}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  @doc """
  Sends a text message.
  """
  def send_message(
        to,
        phone_number_id,
        content,
        custom_config \\ [],
        wa_id \\ nil,
        preview_url \\ true
      ) do
    base = %{
      "messaging_product" => "whatsapp",
      "recipient_type" => "individual",
      "to" => to,
      "type" => "text",
      "text" => %{"preview_url" => preview_url, "body" => content}
    }

    data =
      if not is_nil(wa_id), do: Map.put(base, "context", %{"message_id" => wa_id}), else: base

    Logger.info("Sending message to #{to}")

    case HTTP.post(@endpoint, phone_number_id, data, custom_config) do
      {:ok, response} ->
        Logger.info("Message sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Message not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def send_raction_message(to, phone_number_id, wa_id, custom_config \\ []) do
    data = %{
      "messaging_product" => "whatsapp",
      "recipient_type" => "individual",
      "to" => to,
      "type" => "reaction",
      # \uD83D\uDC4D
      "reaction" => %{"message_id" => wa_id, "emoji" => "\u{1F44D}"}
    }

    Logger.info("Sending emoji reaction to #{to}")

    case HTTP.post(@endpoint, phone_number_id, data, custom_config) do
      {:ok, response} ->
        Logger.info("Message sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Message not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def send_media_message(
        to,
        phone_number_id,
        media_id,
        media_type \\ "image",
        custom_config \\ [],
        caption \\ ""
      ) do
    media_content =
      case media_type do
        "audio" ->
          %{"id" => media_id}

        "video" ->
          %{"id" => media_id, "caption" => caption}

        "image" ->
          %{"id" => media_id, "caption" => caption}

        "application" ->
          %{"id" => media_id, "caption" => caption, "filename" => "#{UUID.uuid1()}.pdf"}
      end

    IO.inspect(media_content, label: "media_content")

    media_type = if media_type == "application", do: "document", else: media_type

    data =
      %{
        "messaging_product" => "whatsapp",
        "recipient_type" => "individual",
        "to" => to,
        "type" => media_type,
        media_type => media_content
      }

    case HTTP.post(@endpoint, phone_number_id, data, custom_config) do
      {:ok, response} ->
        Logger.info("Message sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Message not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def upload_media(
        phone_number_id,
        filename,
        custom_config \\ []
      ) do
    # fields = [ messaging_product: "whatsapp", file: {:file, "filename"}]
    body = %{
      "messaging_product" => "whatsapp"
    }

    fields = [
      file:
        {File.stream!(filename, [], 2048), filename: "443834038808808-18496577713-000-task.png"}
    ]

    case HTTP.post_form(@endpoint_media, phone_number_id, fields, body, custom_config) do
      {:ok, response} ->
        Logger.info("upload_media ...")
        {:ok, response}

      {:error, response} ->
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  defp get_author(data) do
    Static.get_author(data)
  end

  defp get_message_id(data) do
    Static.get_message_id(data)
  end
end
