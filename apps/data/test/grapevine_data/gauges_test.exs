defmodule GrapevineData.GaugesTest do
  use Grapevine.DataCase

  alias GrapevineData.Gauges

  describe "create a gauge" do
    test "successful" do
      game = create_game(create_user())

      {:ok, gauge} = Gauges.create(game, %{
        name: "HP",
        package: "Char 1",
        message: "Char.Vitals",
        value: "hp",
        max: "maxhp",
        color: "red"
      })

      assert gauge.name == "HP"
    end

    test "invalid package" do
      game = create_game(create_user())

      {:error, changeset} = Gauges.create(game, %{
        package: "Char",
      })

      assert changeset.errors[:package]
    end

    test "message matches the package" do
      game = create_game(create_user())

      {:error, changeset} = Gauges.create(game, %{
        package: "Char 1",
        message: "Character.Vitals",
        name: "HP",
        value: "hp",
        max: "maxhp",
        color: "red"
      })

      assert changeset.errors[:message]
    end
  end

  describe "update a gauge" do
    test "successful" do
      game = create_game(create_user())
      gauge = create_gauge(game, %{name: "HP"})

      {:ok, gauge} = Gauges.update(gauge, %{
        name: "SP",
      })

      assert gauge.name == "SP"
    end

    test "invalid" do
      game = create_game(create_user())

      {:error, changeset} = Gauges.create(game, %{
        package: "Char",
      })

      assert changeset.errors[:package]
    end
  end

  describe "deleting a guage" do
    test "successul" do
      game = create_game(create_user())
      gauge = create_gauge(game, %{name: "HP"})

      {:ok, _gauge} = Gauges.delete(gauge)
    end
  end
end
