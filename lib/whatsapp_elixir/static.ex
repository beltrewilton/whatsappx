defmodule WhatsappElixir.Static do
  @moduledoc """
  Utility functions for processing data received from the WhatsApp webhook.
  """

  def handle_notification(data) do
    case get_message_type(data) do
      nil ->
        %Whatsapp.Meta.Request{
          meta_request: [
            status_code: 200,
            waba_id: get_waba_id(data),
            phone_number_id: get_phone_number_id(data),
            display_phone_number: get_display_phone_number(data),
            wa_message_id: get_message_id(data),
            sender_phone_number: get_mobile(data),
            status: get_message_status(data),
            billable: get_pricing_info(data, :billable),
            category: get_pricing_info(data, :category),
            pricing_model: get_pricing_info(data, :pricing_model)
          ]
        }

      _ ->
        %Whatsapp.Client.Sender{
          sender_request: [
            status_code: 200,
            waba_id: get_waba_id(data),
            phone_number_id: get_phone_number_id(data),
            display_phone_number: get_display_phone_number(data),
            wa_message_id: get_message_id(data),
            ref_whatsapp_id: get_ref_whatsapp_id(data),
            sender_phone_number: get_mobile(data),
            message: get_message(data),
            message_type: get_message_type(data),
            flow: is_flow?(data),
            image_id: get_image_id(data),
            sticker_id: get_sticker_id(data),
            audio_id: get_audio_id(data),
            video_id: get_video_id(data),
            image_caption: get_image_caption(data),
            scheduled: false,
            forwarded: is_forwarded?(data)
          ]
        }
    end
  end

  def get_waba_id(data) do
    data["entry"]
    |> List.first()
    |> Map.get("id")
  end

  @doc """
  Checks if the data received from the webhook is a message.
  """
  def is_message(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    Map.has_key?(data, "messages")
  end

  def is_forwarded?(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    case data do
      %{"messages" => [%{"context" => %{"forwarded" => forwarded}} | _]} -> forwarded
      _ -> false
    end
  end
  
  def get_ref_whatsapp_id(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    case data do
      %{"messages" => [%{"context" => %{"id" => id}} | _]} -> id
      _ -> nil
    end
  end

  def pronto(file) do
    file = File.read!(file)
    Jason.decode!(file)
  end

  def is_flow?(data) do
    case get_interactive_response(data) do
      nil ->
        false

      data ->
        if Map.has_key?(data, "nfm_reply") do
          true
        else
          false
        end
    end
  end

  # TODO: uncompleted --
  def get_flow_name(data) do
    case get_interactive_response(data) do
      nil ->
        nil

      data ->
        if Map.has_key?(data, "nfm_reply") do
          data
          |> Map.get("nfm_reply")
          |> Map.get("name")
        else
          nil
        end
    end
  end

  def get_phone_number_id(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "metadata") do
      data["metadata"]
      |> Map.get("phone_number_id")
    end
  end

  def get_display_phone_number(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "metadata") do
      data["metadata"]
      |> Map.get("display_phone_number")
    end
  end

  @doc """
  Extracts the mobile number of the sender from the data received from the webhook.
  """
  def get_mobile(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    cond do
      Map.has_key?(data, "contacts") ->
        data["contacts"]
        |> List.first()
        |> Map.get("wa_id")

      Map.has_key?(data, "statuses") ->
        data["statuses"]
        |> List.first()
        |> Map.get("recipient_id")

      true ->
        nil
    end
  end

  @doc """
  Extracts the name of the sender from the data received from the webhook.
  """
  def get_name(data) do
    contact =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if contact do
      contact["contacts"]
      |> List.first()
      |> Map.get("profile")
      |> Map.get("name")
    else
      nil
    end
  end

  def get_message(data), do: get_message(data, get_message_type(data))

  @doc """
  Extracts the text message of the sender from the data received from the webhook.
  """
  defp get_message(data, "text") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("text")
      |> Map.get("body")
    else
      nil
    end
  end

  defp get_message(data, _), do: nil

  @doc """
  Extracts the message id of the sender from the data received from the webhook.
  """
  def get_message_id(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    cond do
      Map.has_key?(data, "messages") ->
        data["messages"]
        |> List.first()
        |> Map.get("id")

      Map.has_key?(data, "statuses") ->
        data["statuses"]
        |> List.first()
        |> Map.get("id")

      true ->
        nil
    end
  end
  
  def get_response_message_id(response) do
    cond do
      Map.has_key?(response, "messages") ->
        response["messages"]
        |> List.first()
        |> Map.get("id")

      true ->
        nil
    end
  end

  @doc """
  Extracts the timestamp of the message from the data received from the webhook.
  """
  def get_message_timestamp(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("timestamp")
    else
      nil
    end
  end

  @doc """
  Extracts the response of the interactive message from the data received from the webhook.
  """
  defp get_interactive_response(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("interactive")
    else
      nil
    end
  end

  @doc """
  Extracts the location of the sender from the data received from the webhook.
  """
  def get_location(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("location")
    else
      nil
    end
  end

  @doc """
  Extracts the image of the sender from the data received from the webhook.
  """
  def get_image(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("image")
    else
      nil
    end
  end

  @doc """
  Extracts the document of the sender from the data received from the webhook.
  """
  def get_document(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("document")
    else
      nil
    end
  end
  
  def get_image_id(data), do: get_image_id(data, get_message_type(data))

  @doc """
  Extracts the audio id of the sender from the data received from the webhook.
  #TODO: implement ffmpeg function
  """
  def get_image_id(data, "image") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("image")
      |> Map.get("id")
    else
      nil
    end
  end

  def get_image_id(_data, _), do: nil
  
  
  def get_sticker_id(data), do: get_sticker_id(data, get_message_type(data))

  @doc """
  Extracts the audio id of the sender from the data received from the webhook.
  #TODO: implement ffmpeg function
  """
  def get_sticker_id(data, "sticker") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("sticker")
      |> Map.get("id")
    else
      nil
    end
  end

  def get_sticker_id(_data, _), do: nil
  

  def get_audio_id(data), do: get_audio_id(data, get_message_type(data))

  @doc """
  Extracts the audio id of the sender from the data received from the webhook.
  #TODO: implement ffmpeg function
  """
  def get_audio_id(data, "audio") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("audio")
      |> Map.get("id")
    else
      nil
    end
  end

  def get_audio_id(_data, _), do: nil

  def get_video_id(data), do: get_video_id(data, get_message_type(data))

  @doc """
  Extracts the audio id of the sender from the data received from the webhook.
  #TODO: implement ffmpeg function
  """
  def get_video_id(data, "video") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("video")
      |> Map.get("id")
    else
      nil
    end
  end

  def get_video_id(_data, _), do: nil

  @doc """
  Extracts the video of the sender from the data received from the webhook.
  """
  def get_video(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("video")
    else
      nil
    end
  end
  
  
  def get_image_caption(data), do: get_image_caption(data, get_message_type(data))

  @doc """
  Extracts the audio id of the sender from the data received from the webhook.
  #TODO: implement ffmpeg function
  """
  def get_image_caption(data, "image") do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("image")
      |> Map.get("caption")
    else
      nil
    end
  end

  def get_image_caption(_data, _), do: nil
  

  @doc """
  Gets the type of the message sent by the sender from the data received from the webhook.
  """
  def get_message_type(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "messages") do
      data["messages"]
      |> List.first()
      |> Map.get("type")
    else
      nil
    end
  end

  @doc """
  Extracts the message status [delivered|sent|readed|] of the message from the data received from the webhook.
  """
  def get_message_status(data) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "statuses") do
      data["statuses"]
      |> List.first()
      |> Map.get("status")
    else
      nil
    end
  end

  def get_pricing_info(data, field) do
    data =
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")

    if Map.has_key?(data, "statuses") do
      if Map.has_key?(List.first(data["statuses"]), "pricing") do
        List.first(data["statuses"])
        |> Map.get("pricing")
        |> Map.get(Atom.to_string(field))
      else
        nil
      end
    else
      nil
    end
  end

  @doc """
  Helper function to check if the field changed in the data received from the webhook.
  """
  def changed_field(data) do
    data["entry"]
    |> List.first()
    |> Map.get("changes")
    |> List.first()
    |> Map.get("field")
  end

  @doc """
  Extracts the author of the message from the data received from the webhook.
  """
  def get_author(data) do
    try do
      data["entry"]
      |> List.first()
      |> Map.get("changes")
      |> List.first()
      |> Map.get("value")
      |> Map.get("messages")
      |> List.first()
      |> Map.get("from")
    rescue
      _ -> nil
    end
  end

  def util_func(json_file) do
    {:ok, content} = File.read(json_file)
    Jason.decode!(content)
  end
end
