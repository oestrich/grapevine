defmodule Web.ContactController do
  use Web, :controller

  alias Grapevine.Contact

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"contact" => params}) do
    Contact.send(params)

    conn
    |> put_flash(:info, "Sent! Thanks for contacting us.")
    |> redirect(to: Routes.contact_path(conn, :new))
  end
end
