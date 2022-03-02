defmodule Yggdrasil.Subscriber.Adapter.Icon.Message do
  @moduledoc """
  This module defines functions to deal with ICON 2.0 websocket messages.
  """
  alias Icon.Schema.Type
  alias Yggdrasil.Channel

  @doc """
  Encodes a request for the ICON 2.0 websocket. It receives the `height` and
  the `channel` to build the request.
  """
  @spec encode(pos_integer(), Channel.t()) :: WebSockex.frame() | no_return()
  def encode(height, channel) do
    data =
      height
      |> do_encode(channel)
      |> Jason.encode!()

    {:text, data}
  end

  ##################
  # Encoding helpers

  @spec do_encode(pos_integer(), Channel.t()) :: map()
  defp do_encode(height, channel)

  defp do_encode(height, %Channel{name: %{source: :block} = info}) do
    data = %{height: Type.dump!(Icon.Schema.Types.Integer, height)}

    case info[:data] do
      [_ | _] = events ->
        Map.put(data, :eventFilters, Enum.map(events, &encode_event/1))

      _ ->
        data
    end
  end

  defp do_encode(height, %Channel{name: %{source: :event} = info}) do
    base = %{height: Type.dump!(Icon.Schema.Types.Integer, height)}

    (info[:data] || %{})
    |> encode_event()
    |> Map.merge(base)
  end

  @spec encode_event(map()) :: map() | no_return()
  defp encode_event(data)

  defp encode_event(%{event: header} = data) when is_binary(header) do
    %{event: header}
    |> maybe_add_addr(data)
    |> maybe_add_indexed(data)
    |> maybe_add_data(data)
  end

  defp encode_event(_data) do
    raise ArgumentError, message: "missing event header"
  end

  @spec maybe_add_addr(map(), map()) :: map()
  defp maybe_add_addr(event, %{addr: addr}) do
    Map.put(event, :addr, Type.dump!(Icon.Schema.Types.SCORE, addr))
  end

  defp maybe_add_addr(event, _) do
    event
  end

  @spec maybe_add_indexed(map(), map()) :: map()
  defp maybe_add_indexed(event, data)

  defp maybe_add_indexed(%{event: header} = event, %{indexed: indexed})
       when is_list(indexed) do
    indexed =
      header
      |> get_types()
      |> Enum.zip(indexed)
      |> Enum.map(fn
        {_module, nil} -> nil
        {module, value} -> Type.dump!(module, value)
      end)

    Map.put(event, :indexed, indexed)
  end

  defp maybe_add_indexed(event, _data), do: event

  @spec maybe_add_data(map(), map()) :: map()
  defp maybe_add_data(event, data)

  defp maybe_add_data(%{event: header, indexed: indexed} = event, %{data: data})
       when is_list(indexed) do
    data =
      header
      |> get_types()
      |> Enum.drop(length(indexed))
      |> Enum.zip(data)
      |> Enum.map(fn
        {_module, nil} -> nil
        {module, value} -> Type.dump!(module, value)
      end)

    Map.put(event, :data, data)
  end

  defp maybe_add_data(event, _data), do: event

  @spec get_types(binary()) :: [module()] | no_return()
  defp get_types(header) do
    header
    |> String.splitter(["(", ",", ")"], trim: true)
    |> Enum.into([])
    |> tl()
    |> Enum.map(fn
      "int" -> Icon.Schema.Types.Integer
      "str" -> Icon.Schema.Types.String
      "bytes" -> Icon.Schema.Types.BinaryData
      "bool" -> Icon.Schema.Types.Boolean
      "Address" -> Icon.Schema.Types.Address
    end)
  end
end
