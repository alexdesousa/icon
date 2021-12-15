defmodule Icon.Types.ErrorTest do
  use ExUnit.Case, async: true

  alias Icon.Types.{Error, Schema}

  describe "new/1 with map" do
    test "defaults to Server error when no code is provided" do
      assert %Error{
               code: -32_000,
               reason: :server_error,
               domain: :request,
               message: "Server error",
               data: nil
             } = Error.new([])
    end

    test "overrides message" do
      assert %Error{
               code: -32_000,
               reason: :server_error,
               domain: :request,
               message: "Some other error",
               data: nil
             } = Error.new(message: "Some other error")
    end

    test "unflattens errors in schema" do
      expected =
        "boolean is required, integer is invalid, schema.address is required"

      schema = %{
        integer: :integer,
        boolean: {:boolean, required: true},
        schema: %{
          address: {:address, required: true}
        }
      }

      params = %{
        "integer" => "INVALID",
        "schema" => %{}
      }

      assert {
               :error,
               %Error{
                 code: -32_602,
                 reason: :invalid_params,
                 domain: :unknown,
                 message: ^expected
               }
             } =
               schema
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
               |> Schema.apply()
    end

    for {reason, code, domain, message} <- [
          {:parse_error, -32_700, :request, "Parse error"},
          {:invalid_request, -32_600, :request, "Invalid request"},
          {:method_not_found, -32_601, :request, "Method not found"},
          {:invalid_params, -32_602, :request, "Invalid params"},
          {:internal_error, -32_603, :request, "Internal error"},
          {:server_error, Enum.to_list(-32_099..-32_000), :request,
           "Server error"},
          {:system_error, -31_000, :request, "System error"},
          {:pool_overflow, -31_001, :request, "Pool overflow"},
          {:pending, -31_002, :request, "Pending"},
          {:executing, -31_003, :request, "Executing"},
          {:not_found, -31_004, :request, "Not found"},
          {:lack_of_resource, -31_005, :request, "Lack of resource"},
          {:timeout, -31_006, :request, "Timeout"},
          {:system_timeout, -31_007, :request, "System timeout"},
          {:unknown_failure, -30_001, :contract, "Unknown failure"},
          {:contract_not_found, -30_002, :contract, "Contract not found"},
          {:method_not_found, -30_003, :contract, "Method not found"},
          {:method_not_payable, -30_004, :contract, "Method not payable"},
          {:illegal_format, -30_005, :contract, "Illegal format"},
          {:invalid_parameter, -30_006, :contract, "Invalid parameter"},
          {:invalid_instance, -30_007, :contract, "Invalid instance"},
          {:invalid_container_access, -30_008, :contract,
           "Invalid container access"},
          {:access_denied, -30_009, :contract, "Access denied"},
          {:out_of_step, -30_010, :contract, "Out of step"},
          {:out_of_balance, -30_011, :contract, "Out of balance"},
          {:timeout_error, -30_012, :contract, "Timeout error"},
          {:stack_overflow, -30_013, :contract, "Stack overflow"},
          {:skip_transaction, -30_014, :contract, "Skip transaction"},
          {:reverted, Enum.to_list(-30_999..-30_032), :contract, "Reverted"}
        ] do
      test "generates correct error for #{reason} (#{domain})" do
        reason = unquote(reason)
        code = unquote(code)
        codes = unquote(code)
        domain = unquote(domain)
        message = unquote(message)

        if is_integer(code) do
          assert %Error{
                   code: ^code,
                   reason: ^reason,
                   domain: ^domain,
                   message: ^message,
                   data: nil
                 } = Error.new(code: code)
        else
          for code <- codes do
            assert %Error{
                     code: ^code,
                     reason: ^reason,
                     domain: ^domain,
                     message: ^message,
                     data: nil
                   } = Error.new(code: code)
          end
        end
      end
    end
  end
end
