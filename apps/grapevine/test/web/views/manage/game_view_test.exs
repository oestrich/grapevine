defmodule Web.Manage.GameViewTest do
  use Grapevine.DataCase

  alias Web.Manage.GameView

  describe "games/status json" do
    setup do
      game = game_struct(%{})
      game = %{game | connections: []}

      %{game: game}
    end

    test "includes names", %{game: game} do
      json = GameView.render("status.json", %{game: game})

      assert json.game == game.short_name
      assert json.display_name == game.name
    end

    test "includes homepage_url if available", %{game: game} do
      game = %{game | homepage_url: nil}
      json = GameView.render("status.json", %{game: game})
      refute Map.has_key?(json, :homepage_url)

      game = %{game | homepage_url: "https://example.com"}
      json = GameView.render("status.json", %{game: game})
      assert json.homepage_url == game.homepage_url
    end

    test "includes user agent if available", %{game: game} do
      game = %{game | user_agent: nil}
      json = GameView.render("status.json", %{game: game})
      refute Map.has_key?(json, :user_agent)
      refute Map.has_key?(json, :user_agent_repo_url)

      game = %{game | user_agent: "ExVenture 0.26.0"}
      json = GameView.render("status.json", %{game: game})
      assert json.user_agent == game.user_agent
    end

    test "includes description if available", %{game: game} do
      game = %{game | description: nil}
      json = GameView.render("status.json", %{game: game})
      refute Map.has_key?(json, :description)

      game = %{game | description: "A game about..."}
      json = GameView.render("status.json", %{game: game})
      assert json.description == game.description
    end

    test "includes connections if available", %{game: game} do
      game = %{game | connections: []}
      json = GameView.render("status.json", %{game: game})
      refute Map.has_key?(json, :connections)

      game = %{game | connections: [%{key: "key", type: "web", url: "https://example.com/play"}]}
      json = GameView.render("status.json", %{game: game})
      assert length(json.connections) == 1
    end
  end
end
