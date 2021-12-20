defmodule Icon.Schema.Error do
  @moduledoc """
  This module defines an ICON 2.0 error.
  """
  alias Icon.Schema

  @typedoc """
  Domain of the error.
  """
  @type domain :: :request | :contract | :unknown

  @typedoc """
  Errors.
  """
  @type error ::
          :parse_error
          | :invalid_request
          | :method_not_found
          | :invalid_params
          | :internal_error
          | :server_error
          | :system_error
          | :pool_overflow
          | :pending
          | :executing
          | :not_found
          | :lack_of_resource
          | :timeout
          | :system_timeout
          | score_error()

  @typedoc """
  SCORE errors.
  """
  @type score_error ::
          :score_unknown_failure
          | :score_contract_not_found
          | :score_method_not_found
          | :score_method_not_payable
          | :score_illegal_format
          | :score_invalid_parameter
          | :score_invalid_instance
          | :score_invalid_container_access
          | :score_access_denied
          | :score_out_of_step
          | :score_out_of_balance
          | :score_timeout_error
          | :score_stack_overflow
          | :score_skip_transaction
          | :score_reverted

  @doc """
  An error.
  """
  defstruct [:code, :reason, :domain, :message, :data]

  @typedoc """
  An error.
  """
  @type t :: %__MODULE__{
          code: integer(),
          reason: error(),
          domain: domain(),
          message: binary(),
          data: any()
        }

  @doc """
  Creates a new error given a `schema_or_map_or_keyword`.
  """
  @spec new(Schema.state() | map() | keyword()) :: t()
  def new(schema_or_map_keyword)

  def new(%Schema{is_valid?: false} = schema) do
    %__MODULE__{
      code: -32_602,
      reason: reason(schema),
      domain: :unknown,
      message: message(schema)
    }
  end

  def new(error) do
    reason = error[:reason]
    code = error[:code] || if reason, do: code(reason), else: -32_000

    %__MODULE__{
      code: code,
      reason: reason || reason(code),
      domain: domain(code),
      message: message(code, error[:message]),
      data: error[:data]
    }
  end

  #################
  # Private helpers

  @spec code(error()) :: integer()
  defp code(reason)
  defp code(:parse_error), do: -32_700
  defp code(:invalid_request), do: -32_600
  defp code(:method_not_found), do: -32_601
  defp code(:invalid_params), do: -32_602
  defp code(:internal_error), do: -32_603
  defp code(:server_error), do: -32_000
  defp code(:system_error), do: -31_000
  defp code(:pool_overflow), do: -31_001
  defp code(:pending), do: -31_002
  defp code(:executing), do: -31_003
  defp code(:not_found), do: -31_004
  defp code(:lack_of_resource), do: -31_005
  defp code(:timeout), do: -31_006
  defp code(:system_timeout), do: -31_007
  defp code(:score_unknown_failure), do: -30_001
  defp code(:score_contract_not_found), do: -30_002
  defp code(:score_method_not_found), do: -30_003
  defp code(:score_method_not_payable), do: -30_004
  defp code(:score_illegal_format), do: -30_005
  defp code(:score_invalid_parameter), do: -30_006
  defp code(:score_invalid_instance), do: -30_007
  defp code(:score_invalid_container_access), do: -30_008
  defp code(:score_access_denied), do: -30_009
  defp code(:score_out_of_step), do: -30_010
  defp code(:score_out_of_balance), do: -30_011
  defp code(:score_timeout_error), do: -30_012
  defp code(:score_stack_overflow), do: -30_013
  defp code(:score_skip_transaction), do: -30_014
  defp code(:score_reverted), do: -30_032

  @spec reason(integer() | Schema.state()) :: error()
  defp reason(code)
  defp reason(%Schema{}), do: :invalid_params
  defp reason(-32_700), do: :parse_error
  defp reason(-32_600), do: :invalid_request
  defp reason(-32_601), do: :method_not_found
  defp reason(-32_602), do: :invalid_params
  defp reason(-32_603), do: :internal_error
  defp reason(code) when -32_000 >= code and code >= -32_099, do: :server_error
  defp reason(-31_000), do: :system_error
  defp reason(-31_001), do: :pool_overflow
  defp reason(-31_002), do: :pending
  defp reason(-31_003), do: :executing
  defp reason(-31_004), do: :not_found
  defp reason(-31_005), do: :lack_of_resource
  defp reason(-31_006), do: :timeout
  defp reason(-31_007), do: :system_timeout
  defp reason(-30_001), do: :score_unknown_failure
  defp reason(-30_002), do: :score_contract_not_found
  defp reason(-30_003), do: :score_method_not_found
  defp reason(-30_004), do: :score_method_not_payable
  defp reason(-30_005), do: :score_illegal_format
  defp reason(-30_006), do: :score_invalid_parameter
  defp reason(-30_007), do: :score_invalid_instance
  defp reason(-30_008), do: :score_invalid_container_access
  defp reason(-30_009), do: :score_access_denied
  defp reason(-30_010), do: :score_out_of_step
  defp reason(-30_011), do: :score_out_of_balance
  defp reason(-30_012), do: :score_timeout_error
  defp reason(-30_013), do: :score_stack_overflow
  defp reason(-30_014), do: :score_skip_transaction

  defp reason(code) when -30_032 >= code and code >= -30_999,
    do: :score_reverted

  @spec domain(integer()) :: domain()
  defp domain(code)
  defp domain(code) when -30_000 >= code and code >= -30_999, do: :contract
  defp domain(_), do: :request

  @spec message(nil | binary() | Schema.state()) :: binary()
  @spec message(nil | integer(), nil | binary() | Schema.state()) :: binary()
  defp message(code \\ nil, message)
  defp message(_code, message) when is_binary(message), do: message
  defp message(-32_700, _), do: "Parse error"
  defp message(-32_600, _), do: "Invalid request"
  defp message(-32_601, _), do: "Method not found"
  defp message(-32_602, _), do: "Invalid params"
  defp message(-32_603, _), do: "Internal error"
  defp message(-31_000, _), do: "System error"
  defp message(-31_001, _), do: "Pool overflow"
  defp message(-31_002, _), do: "Pending"
  defp message(-31_003, _), do: "Executing"
  defp message(-31_004, _), do: "Not found"
  defp message(-31_005, _), do: "Lack of resource"
  defp message(-31_006, _), do: "Timeout"
  defp message(-31_007, _), do: "System timeout"
  defp message(-30_001, _), do: "Unknown failure"
  defp message(-30_002, _), do: "Contract not found"
  defp message(-30_003, _), do: "Method not found"
  defp message(-30_004, _), do: "Method not payable"
  defp message(-30_005, _), do: "Illegal format"
  defp message(-30_006, _), do: "Invalid parameter"
  defp message(-30_007, _), do: "Invalid instance"
  defp message(-30_008, _), do: "Invalid container access"
  defp message(-30_009, _), do: "Access denied"
  defp message(-30_010, _), do: "Out of step"
  defp message(-30_011, _), do: "Out of balance"
  defp message(-30_012, _), do: "Timeout error"
  defp message(-30_013, _), do: "Stack overflow"
  defp message(-30_014, _), do: "Skip transaction"

  defp message(code, _) when -32_000 >= code and code >= -32_099 do
    "Server error"
  end

  defp message(code, _) when -30_032 >= code and code >= -30_999 do
    "Reverted"
  end

  defp message(_code, %Schema{errors: errors}) do
    flatten_errors(errors)
  end

  @spec flatten_errors(nil | binary(), binary() | map()) :: binary()
  defp flatten_errors(root \\ nil, errors)

  defp flatten_errors(nil, errors) when is_map(errors) do
    errors
    |> Stream.map(fn {key, value} -> flatten_errors("#{key}", value) end)
    |> Enum.join(", ")
  end

  defp flatten_errors(root, errors) when is_map(errors) do
    errors
    |> Stream.map(fn {key, message} ->
      flatten_errors("#{root}.#{key}", message)
    end)
    |> Enum.join(", ")
  end

  defp flatten_errors(key, message) do
    "#{key} #{message}"
  end
end
