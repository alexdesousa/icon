defmodule Icon.Types.SignatureTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Signature

  describe "type/0" do
    test "it's a string" do
      assert :string = Signature.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid signature, returns said signature" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert {:ok, ^signature} = Signature.cast(signature)
    end

    test "when it's not a valid signature, errors" do
      assert :error = Signature.cast("INVALID")
      assert :error = Signature.cast(42)
      assert :error = Signature.cast(nil)
      assert :error = Signature.cast(:atom)
      assert :error = Signature.cast(%{})
      assert :error = Signature.cast([])
    end
  end

  describe "load/1" do
    test "delegates EOA signaturees to cast/1" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert Signature.load(signature) == Signature.cast(signature)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert Signature.dump(signature) == Signature.cast(signature)
    end
  end
end
