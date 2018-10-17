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

    resources("/chat", ChatController, only: [:index, :show])

    get("/conduct", PageController, :conduct)

    resources("/connections", ConnectionController, only: [:delete])

    get("/docs", PageController, :docs)

    resources("/games/mine", UserGameController, only: [:index, :create])

    resources("/games", GameController, only: [:index, :show, :edit, :update]) do
      resources("/connections", ConnectionController, only: [:create])
    end

    post("/games/:id/regenerate", GameController, :regenerate)

    get("/media", PageController, :media)

    resources("/register", RegistrationController, only: [:new, :create])

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end
end
