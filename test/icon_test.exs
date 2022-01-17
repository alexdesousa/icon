defmodule IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.{Error, Types.Transaction}

  describe "get_balance/1" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the request is successful, returns own balance in loop", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_balance(identity)
    end

    test "when the balance is not valid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast balance to loop"
              }} = Icon.get_balance(identity)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_balance(identity)
    end
  end

  describe "get_balance/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")
      wallet = "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"

      {:ok, bypass: bypass, identity: identity, wallet: wallet}
    end

    test "when the request is successful, returns own balance in loop", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_balance(identity, wallet)
    end

    test "when the balance is not valid, returns error", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast balance to loop"
              }} = Icon.get_balance(identity, wallet)
    end

    test "when server responds with an error, errors", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_balance(identity, wallet)
    end
  end

  describe "get_total_supply/1" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the request is successful, returns own ICX total supply in loop",
         %{
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_total_supply(identity)
    end

    test "when the total supply is not valid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast total supply to loop"
              }} = Icon.get_total_supply(identity)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_total_supply(identity)
    end
  end

  describe "get_transaction_result/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      {:ok, bypass: bypass, identity: identity, hash: hash}
    end

    test "when the request is successful, returns transaction result", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result_from_json("test/fixtures/transaction_result.json")

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.get_transaction_result(identity, hash)
    end

    test "when the result is not valid, returns error", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.get_transaction_result(identity, hash)
    end

    test "when server responds with an error, errors", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_transaction_result(identity, hash)
    end
  end

  @spec result(any()) :: binary()
  defp result(result) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => result
    }
    |> Jason.encode!()
  end

  @spec result_from_json(Path.t()) :: binary()
  defp result_from_json(path) when is_binary(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> result()
  end

  @spec error(map()) :: binary()
  defp error(error) when is_map(error) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "error" => error
    }
    |> Jason.encode!()
  end
end
