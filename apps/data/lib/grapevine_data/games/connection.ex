defmodule GrapevineData.Games.Connection do
  @moduledoc """
  Connection Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  @types ["web", "telnet", "secure telnet"]

  schema "connections" do
    field(:key, Ecto.UUID, read_after_writes: true)
    field(:type, :string)
    field(:url, :string)
    field(:host, :string)
    field(:port, :integer)
    field(:certificate, :string)

    field(:poll_enabled, :boolean, default: false)
    field(:supports_mssp, :boolean, default: false)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:type])
    |> validate_required([:type])
    |> validate_inclusion(:type, @types)
    |> validate_by_type(params)
    |> unique_constraint(:type, name: :connections_game_id_type_index)
  end

  def update_changeset(struct, params) do
    struct
    |> change()
    |> validate_by_type(params)
  end

  def mssp_changeset(struct, supports_mssp) do
    struct
    |> change()
    |> put_change(:supports_mssp, supports_mssp)
  end

  def poll_changeset(struct, poll_enabled) do
    struct
    |> change()
    |> put_change(:poll_enabled, poll_enabled)
  end

  defp validate_by_type(changeset, params) do
    case get_field(changeset, :type) do
      "web" ->
        changeset
        |> cast(params, [:url])
        |> validate_required([:url])
        |> validate_format(:url, ~r/^https?:\/\/\w+.\w+/)
        |> validate_url()

      "telnet" ->
        changeset
        |> cast(params, [:host, :port])
        |> validate_required([:host, :port])
        |> validate_inclusion(:port, 0..65_535)
        |> validate_exclusion(:port, [80, 443])

      "secure telnet" ->
        changeset
        |> cast(params, [:host, :port, :certificate])
        |> validate_required([:host, :port])
        |> validate_inclusion(:port, 0..65_535)
        |> validate_exclusion(:port, [80, 443])
        |> validate_ceritifcate()
    end
  end

  defp validate_url(changeset) do
    case get_change(changeset, :url) do
      nil ->
        changeset

      url ->
        case String.match?(url, ~r/grapevine\.haus/) do
          true ->
            add_error(changeset, :url, "cannot list Grapevine as a web client")

          false ->
            changeset
        end
    end
  end

  defp validate_ceritifcate(changeset) do
    case get_change(changeset, :certificate) do
      nil ->
        changeset

      certificate ->
        case :public_key.pem_decode(certificate) do
          [{:Certificate, _cert, :not_encrypted}] ->
            changeset

          _ ->
            add_error(changeset, :certificate, "is invlaid")
        end
    end
  end
end
