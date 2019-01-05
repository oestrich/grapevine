defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Web.Plugs.FetchUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser # Use the default browser stack

    get("/", PageController, :index)

    resources("/achievements", AchievementController, only: [:edit, :update, :delete])

    resources("/chat", ChatController, only: [:index, :show])

    get("/conduct", PageController, :conduct)

    resources("/connections", ConnectionController, only: [:delete])

    get("/docs", PageController, :docs)

    resources("/events", EventController, only: [:edit, :update, :delete])

    resources("/games/mine", UserGameController, only: [:index])

    resources("/games", GameController, only: [:index, :show, :new, :create, :edit, :update]) do
      resources("/achievements", AchievementController, only: [:index, :new, :create])

      resources("/connections", ConnectionController, only: [:create])

      resources("/events", EventController, only: [:index, :new, :create])

      resources("/redirect-uris", RedirectURIController, only: [:create])

      get("/stats/players", GameStatisticController, :players, as: :statistic)
    end

    post("/games/:id/regenerate", GameController, :regenerate)

    get("/media", PageController, :media)

    if Mix.env == :dev do
      get("/colors", PageController, :colors)
    end

    resources("/mssp", MSSPController, only: [:index])

    resources("/redirect-uris", RedirectURIController, only: [:delete])

    resources("/register", RegistrationController, only: [:new, :create])

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end
end
