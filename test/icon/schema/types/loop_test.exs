defmodule Icon.Schema.Types.LoopTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Loop

  describe "load/1" do
    test "delegates to integer's load/1" do
      loop = "0x2a"
      assert Loop.load(loop) == Icon.Schema.Types.Integer.load(loop)
    end
  end

  describe "dump/1" do
    test "delegates to integer's dump/1" do
      loop = 42
      assert Loop.dump(loop) == Icon.Schema.Types.Integer.dump(loop)
    end
  end
end
