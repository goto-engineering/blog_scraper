# Blog Scraper

Scrapes blogs for new entries. Stores existing article URLs in a local SQLite database and only shows new entries. Yes, I've reimplemented RSS feeds.

## Setup

Comment in the Ecto lines to create the database and run the migration once, then comment them back out.

## Configuration

Copy `blogs.exs.example` to `blogs.exs`. There are two parts, extractor functions that find the title and URL from an article element, and the list of blogs to scrape. Many WordPress blogs work with the example extractor function.

The list of blogs is defined by tuples containing the name you want displayed, the URL to the blog, the CSS path to individual article elements (e.g. cards, headers, links, titles) on the index page, and an extractor function:
```
{"Blog title", "https://blog-url.com/", @wp_path, &Blogs.default_wp/1}
```
