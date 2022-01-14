defmodule IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.Error

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

  @spec result(any()) :: binary()
  defp result(result) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => result
    }
    |> Jason.encode!()
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
