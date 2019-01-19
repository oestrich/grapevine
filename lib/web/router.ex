defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Web.Plugs.FetchUser)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Web do
    pipe_through(:browser)

    get("/", PageController, :index)

    resources("/chat", ChatController, only: [:index, :show])

    get("/conduct", PageController, :conduct)

    get("/docs", PageController, :docs)

    get("/media", PageController, :media)

    if Mix.env() == :dev do
      get("/colors", PageController, :colors)
    end

    resources("/mssp", MSSPController, only: [:index])

    get("/games/online", GameController, :online)

    resources("/games", GameController, only: [:index, :show]) do
      resources("/achievements", AchievementController, only: [:index])

      get("/stats/players", GameStatisticController, :players, as: :statistic)
    end

    resources("/register", RegistrationController, only: [:new, :create])

    get("/register/reset", RegistrationResetController, :new)
    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)
    post("/register/reset/verify", RegistrationResetController, :update)

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end

  scope "/manage", Web.Manage, as: :manage do
    pipe_through(:browser)

    resources("/achievements", AchievementController, only: [:edit, :update, :delete])

    resources("/connections", ConnectionController, only: [:delete])

    resources("/events", EventController, only: [:edit, :update, :delete])

    resources("/games", GameController, only: [:index, :show, :new, :create, :edit, :update]) do
      resources("/achievements", AchievementController, only: [:index, :new, :create])

      resources("/connections", ConnectionController, only: [:create])

      resources("/events", EventController, only: [:index, :new, :create])

      resources("/redirect-uris", RedirectURIController, only: [:create])
    end

    post("/games/:id/regenerate", GameController, :regenerate)

    resources("/redirect-uris", RedirectURIController, only: [:delete])

    resources("/settings", SettingController, only: [:show, :edit, :update], singleton: true)
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
