#!/usr/bin/env elixir

Mix.install([
  {:httpoison, "~> 1.8"},
  {:floki, "~> 0.32.0"},
  {:ecto_sqlite3, "~> 0.7.5"},
  {:ecto, "~> 3.8"}
])

defmodule PathHelper do
  def relative_file(filename) do
    Path.join(cwd(), filename)
  end

  defp follow_symlink(path) do
    {raw_path, 0} = System.cmd("readlink", [path])

    String.trim(raw_path)
  end

  defp cwd do
    raw_path = __ENV__.file

    path =
      case File.lstat!(raw_path).type do
        :symlink -> follow_symlink(raw_path)
        :regular -> raw_path
      end

    Path.dirname(path)
  end
end

Code.eval_file(PathHelper.relative_file("blogs.exs"))
Code.eval_file(PathHelper.relative_file("ecto.exs"))

defmodule BlogScraper do
  import Ecto.Query

  @timeout 10000

  def start do
    # Comment in once to create DB
    # :ok = Repo.__adapter__().storage_up(Repo.config())

    {:ok, _} = Supervisor.start_link([Repo], strategy: :one_for_one)

    # Comment in once to run migration
    # Ecto.Migrator.run(Repo, [{0, CreateBlogsMigration}], :up, all: true, log_migrations_sql: :debug)

    new_content =
      Blogs.all()
      |> Enum.map(&dispatch/1)
      |> Enum.map(fn task -> Task.await(task, @timeout) end)
      |> Enum.filter(&(Enum.count(&1.posts) > 0))

    Enum.each(new_content, fn post ->
      print_description(post)
      save_to_database(post)
    end)
  end

  defp dispatch({blog_name, url, css_path, extractor}) do
    Task.async(fn ->
      posts = grab_blog(url, css_path, extractor)

      filtered_posts =
        posts
        |> Enum.filter(fn {_name, url} ->
          Post
          |> where(url: ^url)
          |> Repo.all()
          |> Enum.count()
          |> then(&(&1 == 0))
        end)

      %{name: blog_name, posts: filtered_posts}
    end)
  end

  defp grab_blog(url, css_path, extractor) do
    url
    |> fetch
    |> parse(css_path, extractor)
    |> Enum.filter(& &1)
  end

  defp fetch(url) do
    case HTTPoison.get(url, [], hackney: [follow_redirect: true]) do
      {:ok, response} -> response.body
      {:error, error} -> IO.puts(:stderr, "Error fetching #{url}: #{error.reason}")
    end
  end

  defp parse(html, css_path, extractor) do
    {:ok, document} = Floki.parse_document(html)

    Floki.find(document, css_path)
    |> Enum.map(extractor)
  end

  defp print_description(%{name: blog_name, posts: posts}) do
    post_strings =
      Enum.map(posts, fn {title, url} ->
        [:white, url, :cyan, " # ", title, "\n"]
        |> IO.ANSI.format()
      end)

    underline = blog_name |> String.replace(~r/./, "-")

    [blog_name, underline, post_strings]
    |> Enum.each(&IO.puts/1)
  end

  defp save_to_database(%{posts: posts}) do
    Enum.each(posts, fn {_name, url} -> Repo.insert(%Post{url: url}) end)
  end
end

BlogScraper.start()
