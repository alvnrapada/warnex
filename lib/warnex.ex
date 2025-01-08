defmodule Warnex do
  @moduledoc """
  This module is meant to assist in ordering the warnings outputted by this application.

  Initially, you must gather the warnings from the compilation output:

  ```
    rm warnings.log; mix compile --force --all-warnings > warnings.log 2>&1

    OR

    alias Warnex
    Warnex.generate_warnings()
  ```
  """

  @doc """
  Runs the compilation process and generates the warnings.log file.
  Returns :ok if successful, {:error, reason} if the command fails.

  ## Examples

      iex> Warnex.generate_warnings()
      :ok
  """
  def generate_warnings do
    case System.cmd("sh", [
           "-c",
           "rm warnings.log; mix compile --force --all-warnings > warnings.log 2>&1"
         ]) do
      {_, 0} -> :ok
      {error, _} -> {:error, error}
    end
  end

  ## Processing ##

  @doc """
  Describes the total warnings for all files that have warnings

  ## Examples

      iex(1)> Warnex.summary
      [
        ["shared_view.ex", 1],
        ["page_controller.ex", 1],
        ["items.ex", 1],
      ]
  """
  def summary() do
    Enum.group_by(parse_warnings(), fn map ->
      Map.get(map[:location] || %{}, :filename, "unknown")
    end)
    |> Enum.map(fn {filename, warnings} ->
      [filename, warnings |> Enum.count()]
    end)
    |> Enum.sort_by(fn [_head, tail] -> tail end)
    |> Enum.reverse()
  end

  @doc """
  Gives you the next n file warnings

  ## Examples

      iex(1)> Warnex.next(5)

      [
        [
          %{
            message: "missing parentheses for expression following \"else:\" keyword. Parentheses are required to solve ambiguity inside keywords.",
            location: %{
              line: 11,
              filename: "shared_view.ex",
              path: "lib/application_web/views"
            }
          }
        ],
      [...],
      ...
      ]
  """
  def next(n) do
    summary()
    |> Enum.take(n)
    |> Enum.map(fn [filename, _] -> for_file(filename) end)
  end

  @doc """
  Shows all warning counts for all files with warnings

  ## Examples

      iex(1)> Warnex.count
      8
  """
  def count do
    parse_warnings() |> Enum.count()
  end

  @doc """
  Returns the total amount of errors for a specific file

  ## Example

      iex(1)> Warnex.count("shared_view.ex")
      1
  """
  def count(lookup) do
    for_file(lookup) |> Enum.count()
  end

  @doc """
  Returns the warnings for a specific file lookup

  ## Examples

      iex(1)> Warnex.for_file("shared_view.ex")
      [
        %{
          message: "missing parentheses for expression following \"else:\" keyword. Parentheses are required to solve ambiguity inside keywords.",
          location: %{
            line: 11,
            filename: "shared_view.ex",
            path: "lib/application_web/views"
          }
        },
        %{...},
        ...
      ]
  """
  def for_file(lookup) do
    parse_warnings()
    |> Enum.filter(fn %{message: _, location: %{path: _path, filename: filename, line: _line}} ->
      lookup == filename
    end)
  end

  @doc """
  Returns all warnings where the existing warning contains the given string

  ## Examples

      iex(1)> Warnex.for_warning("missing parentheses for expression")
      %{
        "shared_view.ex" => [
          %{
            message: "missing parentheses for expression following \"else:\" keyword. Parentheses are required to solve ambiguity inside keywords.",
            location: %{
              line: 11,
              filename: "shared_view.ex",
              path: "lib/application_web/views"
            }
          }
        ],
        "..." => [...]
      }
  """
  def for_warning(warning) do
    parse_warnings()
    |> Enum.filter(fn %{
                        message: message,
                        location: %{path: _path, filename: _filename, line: _line}
                      } ->
      message |> String.contains?(warning)
    end)
    |> Enum.group_by(fn %{
                          message: _message,
                          location: %{path: _path, filename: filename, line: _line}
                        } ->
      filename
    end)
  end

  ## Parsing ##

  @doc """
  Parses the log output of a compilation into maps

  ## Examples

      iex(1)> Warnex.parse_warnings()
      [
        %{
          message: "variable \"result\" is unused (if the variable is not meant to be used, prefix it with an underscore)",
          location: %{
            line: 44,
            filename: "recurring_call_job_status_cache.ex",
            path: "lib/core_blayze_app/cache"
          }
        },
        %{...},
        ...
      ]
  """
  def parse_warnings do
    "warnings.log"
    |> File.read!()
    # Split by new warnings, but keep the "warning:" prefix for validation
    |> String.split("warning: ")
    # Remove the initial "Compiling" lines
    |> Enum.reject(&String.starts_with?(&1, "Compiling"))
    # Parse each warning block
    |> Enum.map(&parse_warning_block/1)
    # Remove nil entries (invalid warnings)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
  end

  defp parse_warning_block(block) do
    # Split the block into lines and remove empty lines
    lines =
      block
      |> String.split("\n")
      |> Enum.reject(&(&1 == ""))
      |> Enum.reject(&String.starts_with?(&1, "Generated"))

    case lines do
      # Skip empty blocks
      [] ->
        nil

      # Process valid warning blocks
      _ ->
        # Extract the message (first line)
        message =
          lines
          |> List.first()
          |> String.replace(~r/^warning:\s*/, "")
          |> String.trim()

        # Find the location line (usually starts with "└─" or contains a file path)
        location =
          lines
          |> Enum.find(&(String.contains?(&1, "└─") || String.contains?(&1, ".ex:")))

        case parse_location(location) do
          nil -> nil
          loc -> %{message: message, location: loc}
        end
    end
  end

  defp parse_location(nil), do: nil

  defp parse_location(location) do
    # Handle the new format with "└─" prefix
    location =
      if String.contains?(location, "└─") do
        location
        |> String.split("└─")
        |> List.last()
        |> String.trim()
      else
        location
      end

    case String.split(location, ":", parts: 3) do
      [path, line_number | _rest] ->
        case Integer.parse(String.trim(line_number)) do
          {number, _} ->
            parts = String.split(path, "/")
            filename = List.last(parts)

            path =
              parts
              |> Enum.reverse()
              |> tl()
              |> Enum.reverse()
              |> Enum.join("/")
              |> String.trim()

            %{
              filename: filename,
              path: path,
              line: number
            }

          :error ->
            nil
        end

      _ ->
        nil
    end
  end
end
