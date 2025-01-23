defmodule WhatsappElixir.Message do
  alias WhatsappElixir.Static

  defstruct [
    :id,
    :data,
    :content,
    :to,
    :rec_type,
    :type,
    :sender,
    :name,
    :image,
    :video,
    :audio,
    :document,
    :location,
    :interactive
  ]

  def new(data) do
    %WhatsappElixir.Message{
      id: Static.get_message_id(data),
      data: data,
      content: Static.get_message(data) || "",
      to: "",
      rec_type: "individual",
      type: Static.get_message_type(data) || "text",
      sender: Static.get_mobile(data),
      name: Static.get_name(data),
      image: Static.get_image(data),
      video: Static.get_video(data),
      audio: Static.get_audio(data),
      document: Static.get_document(data),
      location: Static.get_location(data),
      interactive: Static.get_interactive_response(data)
    }
  end
end

defmodule Whatsapp.Meta.Request do
  @meta_request [
    status_code: nil,
    waba_id: nil,
    phone_number_id: nil,
    display_phone_number: nil,
    wa_message_id: nil,
    sender_phone_number: nil,
    status: nil,
    billable: nil,
    category: nil,
    pricing_model: nil
  ]

  defstruct meta_request: @meta_request
end

defmodule Whatsapp.Client.Sender do
  @sender_request [
    status_code: nil,
    waba_id: nil,
    phone_number_id: nil,
    display_phone_number: nil,
    wa_message_id: nil,
    sender_phone_number: nil,
    message: nil,
    message_type: nil,
    flow: nil,
    audio_id: nil,
    video_id: nil,
    scheduled: false,
    forwarded: false
  ]

  defstruct sender_request: @sender_request
end
