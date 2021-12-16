defmodule Icon.SchemaTest do
  use ExUnit.Case, async: true
  alias Icon.Schema

  describe "schema helpers" do
    test "list/1 expands a list type" do
      assert {:list, :address} = Schema.list(:address)
    end

    test "any/2 expands a any type" do
      assert {:any, [eoa: :eoa_address, score: :score_address], :type} =
               Schema.any([eoa: :eoa_address, score: :score_address], :type)
    end

    test "enum/1 expands a any type" do
      assert {:enum, [:call, :deploy, :message, :deposit]} =
               Schema.enum([:call, :deploy, :message, :deposit])
    end
  end
end
