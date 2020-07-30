defmodule Extatic.Compiler.Metadata do
  require Logger

  def parse(content) do
    with [frontmatter, content] <- parse_frontmatter(content),
         settings <- parse_yaml(frontmatter) do
      {:ok, settings, content}
    end
  end

  defp parse_frontmatter(content) do
    case String.split(content, ~r/\n-{3,}\n/, parts: 2) do
      [frontmatter, content] -> [frontmatter, content]
      [content] -> [nil, content]
    end
  end

  defp parse_yaml(nil), do: %{}

  defp parse_yaml(yaml) do
    case YamlElixir.read_from_string(yaml) do
      {:ok, res} ->
        res

      _ ->
        Logger.error("Failed parsing frontmatter\n#{yaml}")
        %{}
    end
  end
end