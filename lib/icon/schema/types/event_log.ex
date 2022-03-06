defmodule Icon.Schema.Types.EventLog do
  @moduledoc """
  This module defines an ICON 2.0 event log entry.

  Events are emitted by SCORE contracts and are useful for tracking changes in
  the contract e.g. an event entry for transfering a token from one EOA address
  to another:

  ```json
  {
    "scoreAddress": "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
    "indexed": [
      "Transfer(Address,Address,int)",
      "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
      "hx2e243ad926ac48d15156756fce28314357d49d83"
    ],
    "data": [
      "0x2a"
    ]
  }
  ```

  where:
  - `Transfer(Address,Address,int)` indicates the name of the event and the
    types of the parameters it received.
  - `indexed` is a list of indexed parameters we can use for searching the event
    we want faster.
  - `data` is a list of the non-indexed parameters.

  The type defined in this module, can load events using the Elixir types
  instead of the ICON types e.g. for the previous example, we would have the
  following:

  ```elixir
  %Icon.Schema.Types.EventLog{
    header: "Transfer(Address,Address,int)",
    name: "Transfer",
    score_address: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
    indexed: [
      "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
      "hx2e243ad926ac48d15156756fce28314357d49d83"
    ],
    data: [
      42
    ]
  }
  ```
  """
  use Icon.Schema.Type
  alias Icon.Schema
  alias Icon.Schema.Type

  @doc """
  An event log.
  """
  defstruct header: nil,
            name: nil,
            score_address: nil,
            indexed: [],
            data: []

  @typedoc """
  An event log.
  """
  @type t :: %__MODULE__{
          header: binary(),
          name: binary(),
          score_address: Schema.Types.SCORE.t(),
          indexed: [any()],
          data: [any()]
        }

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value) when is_map(value) do
    event_log =
      value
      |> Type.to_atom_map()
      |> Map.take([:scoreAddress, :indexed, :data])
      |> new()

    {:ok, event_log}
  rescue
    _ ->
      :error
  end

  def load(_) do
    :error
  end

  @spec dump(any()) :: {:ok, map()} | :error
  @impl Icon.Schema.Type
  def dump(event_log)

  def dump(%__MODULE__{} = event_log) do
    event_log = %{
      "scoreAddress" => dump_score_address(event_log),
      "indexed" => dump_indexed(event_log),
      "data" => dump_data(event_log)
    }

    {:ok, event_log}
  rescue
    _ ->
      :error
  end

  def dump(_) do
    :error
  end

  #########
  # Helpers

  @spec new(map()) :: t()
  defp new(map) do
    %__MODULE__{
      header: header(map),
      name: event_name(map),
      score_address: load_score_address(map),
      indexed: load_indexed(map),
      data: load_data(map)
    }
  end

  @spec header(map()) :: binary()
  defp header(%{indexed: [header | _]}), do: header

  @spec event_name(map()) :: binary()
  defp event_name(%{indexed: [header | _]}) do
    header
    |> String.split("(")
    |> List.first()
  end

  @spec load_score_address(map()) :: Icon.Schema.Types.SCORE.t() | no_return()
  defp load_score_address(%{scoreAddress: address}) do
    Type.load!(Icon.Schema.Types.SCORE, address)
  end

  @spec dump_score_address(t()) :: binary() | no_return()
  defp dump_score_address(%__MODULE__{score_address: address}) do
    Type.dump!(Icon.Schema.Types.SCORE, address)
  end

  @spec load_indexed(map()) :: [any()] | no_return()
  defp load_indexed(%{indexed: [header | indexed]}) do
    header
    |> get_types()
    |> Enum.zip(indexed)
    |> Enum.map(fn
      {_module, nil} -> nil
      {module, value} -> Type.load!(module, value)
    end)
  end

  @spec dump_indexed(t()) :: [any()] | no_return()
  defp dump_indexed(%__MODULE__{header: header, indexed: indexed}) do
    indexed =
      header
      |> get_types()
      |> Enum.zip(indexed)
      |> Enum.map(fn
        {_module, nil} -> nil
        {module, value} -> Type.dump!(module, value)
      end)

    [header | indexed]
  end

  @spec load_data(map()) :: [any()] | no_return()
  defp load_data(%{indexed: [header | indexed], data: data}) do
    header
    |> get_types()
    |> Enum.drop(length(indexed))
    |> Enum.zip(data)
    |> Enum.map(fn
      {_module, nil} -> nil
      {module, value} -> Type.load!(module, value)
    end)
  end

  @spec dump_data(map()) :: [any()] | no_return()
  defp dump_data(%__MODULE__{header: header, indexed: indexed, data: data}) do
    header
    |> get_types()
    |> Enum.drop(length(indexed))
    |> Enum.zip(data)
    |> Enum.map(fn
      {_module, nil} -> nil
      {module, value} -> Type.dump!(module, value)
    end)
  end

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
