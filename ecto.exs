Application.put_env(
  :blog_scraper,
  Repo,
  database: PathHelper.relative_file("blog_scraper.db"),
  log: false
)

defmodule Repo do
  use Ecto.Repo,
    otp_app: :blog_scraper,
    adapter: Ecto.Adapters.SQLite3
end

defmodule CreateBlogsMigration do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:url, :string)

      timestamps()
    end
  end
end

defmodule Post do
  use Ecto.Schema

  schema "posts" do
    field(:url)

    timestamps()
  end
end
