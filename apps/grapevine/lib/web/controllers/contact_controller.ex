defmodule Web.ContactController do
  use Web, :controller

  alias Grapevine.Contact
  alias Grapevine.Recaptcha

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, params = %{"contact" => contact_params}) do
    case Recaptcha.valid?(params) do
      true ->
        Contact.send(contact_params)

        conn
        |> put_flash(:info, "Sent! Thanks for contacting us.")
        |> redirect(to: Routes.contact_path(conn, :new))

      false ->
        conn
        |> put_flash(:error, "There was an issue with the captcha. Please try again.")
        |> put_status(422)
        |> render("new.html")
    end
  end
end
