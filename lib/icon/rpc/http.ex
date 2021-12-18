defmodule Icon.RPC.HTTP do
  @moduledoc """
  This module defines functions for performing remote producedure calls on an
  ICON 2.0 node.
  """
  alias Icon.RPC.Request
  alias Icon.Schema.Error

  @typedoc """
  API result.
  """
  @type result :: binary() | list() | map()

  @doc """
  Sends a remote procedure call to an ICON 2.0 node.
  """
  @spec request(Request.t()) :: {:ok, result()} | {:error, Error.t()}
  def request(request)

  def request(%Request{options: options} = request) do
    url = options[:url]
    payload = Jason.encode!(request)

    :post
    |> Finch.build(url, headers(request), payload)
    |> do_request()
  end

  #########
  # Helpers

  @spec headers(Request.t()) :: [{binary(), binary()}]
  defp headers(%Request{options: options}) do
    case options[:timeout] || 0 do
      timeout when timeout > 0 ->
        [
          {"Content-type", "application/json"},
          {"Icon-Options", "#{timeout}"}
        ]

      _ ->
        [{"Content-type", "application/json"}]
    end
  end

  @spec do_request(Finch.Request.t()) ::
          {:ok, result()}
          | {:error, Error.t()}
  defp do_request(%Finch.Request{} = request) do
    case Finch.request(request, Icon.Finch) do
      {:ok, %Finch.Response{body: data}} ->
        do_decode(data)

      {:error, _} ->
        {:error, Error.new(code: -31_000)}
    end
  end

  @spec do_decode(binary()) :: {:ok, result()} | {:error, Error.t()}
  defp do_decode(data) do
    case Jason.decode(data) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      {:ok, %{"error" => error}} ->
        reason =
          Error.new(
            code: error["code"],
            message: error["message"],
            data: error["data"]
          )

        {:error, reason}

      {:error, _} ->
        {:error, Error.new(code: -31_000)}
    end
  end
end
