defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(Phoenix.LiveView.Flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Web.Plugs.FetchUser)
    plug(Web.Plugs.ValidateHost)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Web.Plugs.FetchUser, api: true)
  end

  pipeline :api_authenticated do
    plug(Web.Plugs.EnsureUser, api: true)
  end

  pipeline :logged_in do
    plug(Web.Plugs.EnsureUser)
  end

  pipeline :admin do
    plug(Web.Plugs.EnsureAdmin)
  end

  pipeline :editor do
    plug(Web.Plugs.EnsureEditor)
  end

  pipeline :verified do
    plug(Web.Plugs.EnsureUserVerified)
  end

  pipeline :session_token do
    plug(Web.Plugs.SessionToken)
  end

  pipeline :decanter do
    plug(Web.Plugs.EnsureDecanterEnabled)
  end

  scope "/", Web do
    pipe_through([:browser])

    get("/", PageController, :index)

    get("/about", PageController, :about)

    get("/conduct", PageController, :conduct)

    get("/contact", ContactController, :new)

    post("/contact", ContactController, :create)

    get("/docs", PageController, :docs)

    get("/media", PageController, :media)

    get("/sitemap.xml", PageController, :sitemap)

    if Mix.env() == :dev do
      get("/colors", PageController, :colors)
    end

    resources("/mssp", MSSPController, only: [:index])

    get("/games/online", GameController, :online)

    get("/games/surprise", GameController, :surprise)

    resources("/events", EventController, only: [:index, :show])

    resources("/games", GameController, only: [:index, :show]) do
      resources("/achievements", AchievementController, only: [:index])

      get("/stats", GameStatisticController, :show, as: :statistic)
      get("/stats/players", GameStatisticController, :players, as: :statistic)
    end

    resources("/register", RegistrationController, only: [:new, :create])

    get("/register/verify", RegistrationVerifyController, :show)

    get("/register/reset", RegistrationResetController, :new)
    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)
    post("/register/reset/verify", RegistrationResetController, :update)

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end

  scope "/", Web do
    pipe_through([:browser, :logged_in])

    resources("/chat", ChatController, only: [:index])

    get("/register/finalize", RegistrationController, :finalize)
  end

  scope "/", Web do
    pipe_through([:browser, :session_token])

    get("/games/:game_id/play", PlayController, :show)
  end

  scope "/", Web do
    pipe_through([:api])

    post("/session_tokens", SessionTokenController, :create)
  end

  scope "/decanter", Web.Decanter, as: :decanter do
    pipe_through([:browser, :decanter, :logged_in])

    get("/news/mine", DraftController, :index)

    get("/news/:uid/edit", NewsController, :edit)

    put("/news/:uid", NewsController, :update)

    post("/news/:uid/submit", NewsController, :submit)

    get("/submit", NewsController, :new)

    post("/submit", NewsController, :create)
  end

  scope "/decanter", Web.Decanter, as: :decanter do
    pipe_through([:browser, :decanter])

    get("/", NewsController, :index)

    get("/atom", NewsController, :feed)

    get("/news/:uid", NewsController, :show)
  end

  scope "/decanter/manage", Web.Decanter.Manage, as: :decanter do
    pipe_through([:browser, :decanter, :logged_in, :editor])

    get("/queue", QueueController, :index)

    get("/queue/:uid/edit", QueueController, :edit)

    put("/queue/:uid", QueueController, :update)

    post("/queue/:uid/publish", QueueController, :publish)
  end

  scope "/manage", Web.Manage, as: :manage do
    pipe_through([:browser, :logged_in])

    resources("/achievements", AchievementController, only: [:edit, :update, :delete])

    resources("/characters", CharacterController, only: [:index]) do
      post("/approve", CharacterController, :approve, as: :action)

      post("/deny", CharacterController, :deny, as: :action)
    end

    resources("/connections", ConnectionController, only: [:edit, :update, :delete])

    resources("/events", EventController, only: [:edit, :update, :delete])

    resources("/games", GameController, only: [:show, :new, :create, :edit, :update]) do
      resources("/achievements", AchievementController, only: [:index, :new, :create])

      resources("/client", ClientController, only: [:show, :update], singleton: true)

      resources("/connections", ConnectionController, only: [:create])

      resources("/events", EventController, only: [:index, :new, :create])

      resources("/gauges", GaugeController, only: [:new, :create])

      resources("/redirect-uris", RedirectURIController, only: [:create])

      resources("/site", HostedSiteController, only: [:show, :update], singleton: true)
    end

    post("/games/:id/regenerate", GameController, :regenerate)

    resources("/gauges", GaugeController, only: [:edit, :update, :delete])

    resources("/redirect-uris", RedirectURIController, only: [:delete])

    resources("/settings", SettingController, only: [:show, :edit, :update], singleton: true)
  end

  scope "/admin", Web.Admin, as: :admin do
    pipe_through([:browser, :logged_in, :admin])

    get("/", DashboardController, :index)

    resources("/alerts", AlertController, only: [:index, :show])

    resources("/channels", ChannelController, only: [:index, :show])

    resources("/client_sessions", ClientSessionController, only: [:index])

    resources("/events", EventController)

    resources("/games", GameController, only: [:index, :show])

    resources("/users", UserController, only: [:index, :show])
  end

  scope "/", Web do
    pipe_through([:api, :api_authenticated])

    get("/users/me", UserController, :show)
  end

  scope "/oauth", Web.Oauth do
    pipe_through([:browser, :logged_in, :verified])

    get("/authorize", AuthorizationController, :new)

    resources("/authorizations", AuthorizationController, only: [:update], singleton: true)
  end

  scope "/oauth", Web.Oauth do
    pipe_through([:api])

    post("/token", TokenController, :create)
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
