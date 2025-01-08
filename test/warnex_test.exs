defmodule WarnexTest do
  use ExUnit.Case
  alias Warnex

  @sample_warnings """
  Compiling 5 files (.ex)
  warning: variable "opts" is unused (if the variable is not meant to be used, prefix it with an underscore)
      │
   24 │   def process_warning(warning, opts) do
      │                               ~~~~
      │
      └─ lib/warnex/processor.ex:24:31

  warning: unused alias Logger
      │
    3 │   alias Warnex.Logger
      │   ~
      │
      └─ lib/warnex/parser.ex:3:3

  warning: function parse_warning/1 is unused
      │
   89 │   defp parse_warning(content) do
      │        ~
      │
      └─ lib/warnex/formatter.ex:89:8

  Generated warnex app
  """

  setup do
    # Create a temporary warnings.log file for testing
    File.write!("warnings.log", @sample_warnings)

    :ok
  end

  describe "parse_warnings/0" do
    test "correctly parses warning messages and locations" do
      warnings = Warnex.parse_warnings()

      assert length(warnings) == 3

      # Test first warning
      assert %{
               message:
                 "variable \"opts\" is unused (if the variable is not meant to be used, prefix it with an underscore)",
               location: %{
                 filename: "processor.ex",
                 path: "lib/warnex",
                 line: 24
               }
             } = Enum.at(warnings, 0)

      # Test second warning
      assert %{
               message: "unused alias Logger",
               location: %{
                 filename: "parser.ex",
                 path: "lib/warnex",
                 line: 3
               }
             } = Enum.at(warnings, 1)
    end
  end

  describe "summary/0" do
    test "returns correct warning counts per file" do
      summary = Warnex.summary()

      assert [
               ["processor.ex", 1],
               ["parser.ex", 1],
               ["formatter.ex", 1]
             ] = summary
    end
  end

  describe "count/0" do
    test "returns total number of warnings" do
      assert Warnex.count() == 3
    end
  end

  describe "count/1" do
    test "returns warning count for specific file" do
      assert Warnex.count("parser.ex") == 1
      assert Warnex.count("nonexistent.ex") == 0
    end
  end

  describe "for_file/1" do
    test "returns warnings for specific file" do
      warnings = Warnex.for_file("parser.ex")

      assert length(warnings) == 1

      assert %{
               message: "unused alias Logger",
               location: %{
                 filename: "parser.ex",
                 path: "lib/warnex",
                 line: 3
               }
             } = List.first(warnings)
    end

    test "returns empty list for nonexistent file" do
      assert Warnex.for_file("nonexistent.ex") == []
    end
  end

  describe "for_warning/1" do
    test "returns warnings containing specific string" do
      warnings = Warnex.for_warning("unused")

      assert map_size(warnings) == 3
      assert Map.has_key?(warnings, "parser.ex")
      assert Map.has_key?(warnings, "processor.ex")

      [warning] = warnings["parser.ex"]
      assert warning.message == "unused alias Logger"
    end

    test "returns empty map for nonexistent warning" do
      assert Warnex.for_warning("nonexistent warning") == %{}
    end
  end
end
