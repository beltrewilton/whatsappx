defmodule WhatsappElixir.MediaDl do
  @api_url "https://graph.facebook.com/v22.0/"

  # WhatsappElixir.Audio.get("1301759660809236", "99999", "MDX01")

  def get(media_id, msisdn, campaign, waba_id, task, media_type) do
    cloud_api_token = System.get_env("CLOUD_API_TOKEN")
    task = Atom.to_string(task)

    filename =
      case media_type do
        :audio ->
          recording_path = System.get_env("AUDIO_RECORDING_PATH")
          "#{recording_path}/#{waba_id}-#{msisdn}-#{campaign}-#{task}.ogg"

        :video ->
          recording_path = System.get_env("VIDEO_RECORDING_PATH")
          "#{recording_path}/#{waba_id}-#{msisdn}-#{campaign}-#{task}.mp4"

        :image ->
          recording_path = System.get_env("IMAGE_RECORDING_PATH")
          "#{recording_path}/#{waba_id}-#{msisdn}-#{campaign}-#{task}.png"

        :sticker ->
          recording_path = System.get_env("IMAGE_RECORDING_PATH")
          "#{recording_path}/#{waba_id}-#{msisdn}-#{campaign}-#{task}.gif"
      end

    headers = %{
      "Authorization" => "Bearer #{cloud_api_token}",
      "Content-Type" => "application/json"
    }

    url = @api_url <> media_id

    IO.inspect(url, label: "url")
    IO.inspect(filename, label: "filename")
    IO.inspect(cloud_api_token, label: "cloud_api_token")

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        download(Jason.decode!(body), headers, filename)
        {:ok, filename}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp download(response, headers, filename) do
    resp = HTTPoison.get!(response["url"], headers, stream_to: self(), async: :once)
    {:ok, file} = File.open(filename, [:binary, :write])
    download_file_async(resp, file)
  end

  defp download(_) do
    IO.puts("Error, :(")
  end

  defp download_file_async(resp, file) do
    resp_id = resp.id

    receive do
      %HTTPoison.AsyncStatus{code: status_code, id: ^resp_id} ->
        # IO.inspect(status_code)
        HTTPoison.stream_next(resp)
        download_file_async(resp, file)

      %HTTPoison.AsyncHeaders{headers: headers, id: ^resp_id} ->
        # IO.inspect(headers)
        HTTPoison.stream_next(resp)
        download_file_async(resp, file)

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^resp_id} ->
        IO.binwrite(file, chunk)
        HTTPoison.stream_next(resp)
        download_file_async(resp, file)

      %HTTPoison.AsyncEnd{id: ^resp_id} ->
        File.close(file)
    end
  end

  def upload(phone_number_id, filename) do
    cloud_api_token = System.get_env("CLOUD_API_TOKEN")
    url = "#{@api_url}#{phone_number_id}/media"

    content_type =
      if "application/octet-stream" == MIME.from_path(filename),
        do: "audio/ogg",
        else: MIME.from_path(filename)

    body =
      {:multipart,
       [
         {"messaging_product", "whatsapp"},
         {:file, filename, [{"Content-Type", content_type}]}
       ]}

    headers = %{
      "Authorization" => "Bearer #{cloud_api_token}"
      # "Content-Type" => "application/json"
    }

    IO.inspect(url, label: "url")
    IO.inspect(body, label: "body")
    IO.inspect(headers, label: "headers")

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def retrieve_media(phone_number_id, media_id, filename) do
    cloud_api_token = System.get_env("CLOUD_API_TOKEN")
    url = "#{@api_url}#{media_id}?phone_number_id=#{phone_number_id}"

    headers = %{
      "Authorization" => "Bearer #{cloud_api_token}"
      # "Content-Type" => "application/json"
    }

    IO.inspect(url, label: "url")
    IO.inspect(headers, label: "headers")

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        download(Jason.decode!(body), headers, filename)
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Jason.decode!(reason)}
    end
  end

  def ogg_to_wav(ogg_file_name) do
    wav_file_name = String.replace(ogg_file_name, ".ogg", ".wav")

    command = [
      "-y",
      "-i",
      ogg_file_name,
      "-acodec",
      "pcm_s16le",
      "-ac",
      "1",
      "-ar",
      "16000",
      wav_file_name
    ]

    case System.cmd("ffmpeg", command, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, wav_file_name}

      {output, _} ->
        {:error, "Error ffmpeg: #{output}"}
    end
  end

  def wav_to_ogg(wav_file_name) do
    ogg_file_name = String.replace(wav_file_name, ".wav", ".ogg")

    command = [
      "-y",
      "-i",
      wav_file_name,
      "-c:a",
      "libopus",
      "-ac",
      "1",
      "-ar",
      "16000",
      ogg_file_name
    ]

    case System.cmd("ffmpeg", command, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, ogg_file_name}

      {output, _} ->
        {:error, "Error ffmpeg: #{output}"}
    end
  end
end
