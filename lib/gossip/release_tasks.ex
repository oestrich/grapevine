# From https://github.com/bitwalker/distillery/blob/master/docs/Running%20Migrations.md
defmodule Gossip.ReleaseTasks do
  @moduledoc false

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  @apps [
    :gossip
  ]

  @repos [
    Gossip.Repo
  ]

  def migrate() do
    startup()

    # Run migrations
    Enum.each(@apps, &run_migrations_for/1)

    # Signal shutdown
    IO.puts("Success!")
    :init.stop()
  end

  defp startup() do
    IO.puts("Loading gossip...")

    # Load the code for gossip, but don't start it
    Application.load(:gossip)

    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for gossip
    IO.puts("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 1))
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(Gossip.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end
