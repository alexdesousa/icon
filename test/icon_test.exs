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

    test "when the transaction is successful, returns transaction result", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "hx2e243ad926ac48d15156756fce28314357d49d83",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

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
                to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.get_transaction_result(identity, hash)
    end

    test "when the request times out, returns transaction result with failure",
         %{
           hash: hash,
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "failure" => %{
              "code" => -31_006,
              "message" => "Timeout",
              "data" =>
                "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"
            },
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x0",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "hx2e243ad926ac48d15156756fce28314357d49d83",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :failure,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: %Error{
                  code: -31_006,
                  message: "Timeout",
                  data:
                    "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                  reason: :timeout,
                  domain: :request
                },
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.get_transaction_result(identity, hash, timeout: 5_000)
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

  describe "transfer/4" do
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

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.transfer(identity, recipient, amount)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => recipient,
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: ^recipient,
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.transfer(identity, recipient, amount, timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.transfer(identity, recipient, amount)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.transfer(identity, recipient, amount)
    end
  end

  describe "send_message/4" do
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

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.send_message(identity, recipient, "Hello!")
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => recipient,
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: ^recipient,
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.send_message(identity, recipient, "Hello!", timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.send_message(identity, recipient, "Hello!")
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.send_message(identity, recipient, "Hello!")
    end
  end

  describe "install_score/3" do
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

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, bypass: bypass, identity: identity, content: content}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.install_score(identity, content)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cx0000000000000000000000000000000000000000",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                scoreAddress: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cx0000000000000000000000000000000000000000",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.install_score(identity, content, timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.install_score(identity, content)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.install_score(identity, content)
    end
  end

  describe "update_score/3" do
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

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, bypass: bypass, identity: identity, content: content}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.update_score(identity, score_address, content)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.update_score(identity, score_address, content,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.update_score(identity, score_address, content)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.update_score(identity, score_address, content)
    end
  end

  describe "deposit_shared_fee/4" do
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

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.deposit_shared_fee(identity, score_address, 42)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.deposit_shared_fee(identity, score_address, 42,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.deposit_shared_fee(identity, score_address, 42)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.deposit_shared_fee(identity, score_address, 42)
    end
  end

  describe "withdraw_shared_fee/4" do
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

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.withdraw_shared_fee(identity, score_address)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cummulativeStepUsed: nil,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.withdraw_shared_fee(identity, score_address, 42,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.withdraw_shared_fee(identity, score_address, 42)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

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
              }} = Icon.withdraw_shared_fee(identity, score_address, 42)
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
