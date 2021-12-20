defmodule Icon.RPC.HTTPTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.{HTTP, Request, Request.Goloop}
  alias Icon.Schema.Error

  describe "request/2 with mocked API" do
    setup do
      bypass = Bypass.open()
      Icon.URLBuilder.put_bypass(bypass)
      {:ok, bypass: bypass}
    end

    test "decodes result on successful call", %{bypass: bypass} do
      expected = %{
        "height" => "0x2a",
        "hash" =>
          "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(expected)
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block()

      assert {:ok, ^expected} = HTTP.request(rpc)
    end

    test "when there's no timeout, then there's no special Icon header", %{
      bypass: bypass
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

      assert {:ok, %Request{} = rpc} = Goloop.get_transaction_result(tx_hash)

      assert {:ok, _} = HTTP.request(rpc)
    end

    test "when there's timeout, then there's special Icon header", %{
      bypass: bypass
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
               Goloop.get_transaction_result(tx_hash, timeout: 5_000)

      assert {:ok, _} = HTTP.request(rpc)
    end

    test "when there's no connection, errors" do
      url = "http://unexistent"
      assert {:ok, %Request{} = rpc} = Goloop.get_last_block()

      rpc = %{rpc | options: Keyword.put(rpc.options, :url, url)}

      assert {:error,
              %Error{
                code: -31_000,
                data: nil,
                domain: :request,
                message: "System error",
                reason: :system_error
              }} = HTTP.request(rpc)
    end

    test "when the API returns an error, errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            "code" => -31_004,
            "message" => "Not found"
          })

        Plug.Conn.resp(conn, 404, error)
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block()

      assert {:error,
              %Error{
                code: -31_004,
                data: nil,
                domain: :request,
                message: "Not found",
                reason: :not_found
              }} = HTTP.request(rpc)
    end

    test "when payload does not conform with API, errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      assert {:ok, %Request{} = rpc} = Goloop.get_last_block()

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
      assert {:ok, %Request{} = rpc} = Goloop.get_last_block()
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
