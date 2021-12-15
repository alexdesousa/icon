defmodule Icon.Types.SignatureTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Signature

  describe "load/1" do
    test "when it's a valid signature, returns said signature" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert {:ok, ^signature} = Signature.load(signature)
    end

    test "when it's not a valid signature, errors" do
      assert :error = Signature.load("INVALID")
      assert :error = Signature.load(42)
      assert :error = Signature.load(nil)
      assert :error = Signature.load(:atom)
      assert :error = Signature.load(%{})
      assert :error = Signature.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert Signature.dump(signature) == Signature.load(signature)
    end
  end
end
