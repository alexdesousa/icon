defmodule Icon.RPC.HTTPTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.{HTTP, Identity, Request, Request.Goloop}
  alias Icon.Schema.Error

  describe "request/2 with mocked API" do
    setup do
      bypass = Bypass.open()

      identity =
        Identity.new(
          private_key:
            "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf",
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "decodes result on successful call", %{
      bypass: bypass,
      identity: identity
    } do
      expected = %{
        "height" => "0x2a",
        "hash" =>
          "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(expected)
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block(identity)

      assert {:ok, ^expected} = HTTP.request(rpc)
    end

    test "when there's no timeout, then there's no special Icon header", %{
      bypass: bypass,
      identity: identity
    } do
      tx_hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(%{"txHash" => tx_hash})

        assert Enum.all?(conn.req_headers, fn {name, _} ->
                 name != "icon-options"
               end)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} =
               Goloop.get_transaction_result(identity, tx_hash)

      assert {:ok, _} = HTTP.request(rpc)
    end

    test "when there's timeout, then there's special Icon header", %{
      bypass: bypass,
      identity: identity
    } do
      tx_hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(%{"txHash" => tx_hash})

        assert Enum.any?(conn.req_headers, fn {name, value} ->
                 name == "icon-options" and value == "5000"
               end)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} =
               Goloop.get_transaction_result(identity, tx_hash, timeout: 5_000)

      assert {:ok, _} = HTTP.request(rpc)
    end

    test "when there's no connection, errors" do
      identity = Identity.new(node: "http://unexistent")

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_000,
                data: nil,
                domain: :request,
                message: "System error",
                reason: :system_error
              }} = HTTP.request(rpc)
    end

    test "when the API returns an error, errors", %{
      bypass: bypass,
      identity: identity
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            "code" => -31_004,
            "message" => "Not found"
          })

        Plug.Conn.resp(conn, 404, error)
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_004,
                data: nil,
                domain: :request,
                message: "Not found",
                reason: :not_found
              }} = HTTP.request(rpc)
    end

    test "when payload does not conform with API, errors", %{
      bypass: bypass,
      identity: identity
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_000,
                data: nil,
                domain: :request,
                message: "System error",
                reason: :system_error
              }} = HTTP.request(rpc)
    end
  end

  describe "request/1 without mocked API" do
    test "connects with default node" do
      assert {:ok, %Request{} = rpc} =
               Identity.new()
               |> Goloop.get_last_block()

      assert {:ok, block} = HTTP.request(rpc)
      assert is_map(block)
    end
  end

  @spec result(map()) :: binary()
  defp result(result) when is_map(result) do
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
