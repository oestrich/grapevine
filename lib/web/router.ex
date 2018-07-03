defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
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

    resources("/config", ConfigController, only: [:show], singleton: true)

    put("/config/subscriptions", SubscriptionController, :update)

    get("/docs", PageController, :docs)

    resources("/register", RegistrationController, only: [:new, :create])

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end
end
