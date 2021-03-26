defmodule Still.Preprocessor.Slime do
  @moduledoc """
  Renders a Slime file. See `Still.Preprocessor.Renderer` and
  `Still.Preprocessor.EEx.Renderer`.
  """

  require Slime

  alias Still.Preprocessor
  alias Still.Preprocessor.Slime.Renderer

  use Preprocessor

  @impl true
  def render(file) do
    %{file | content: do_render(file), extension: ".html"}
  end

  defp do_render(
         %{
           metadata: metadata,
           input_file: input_file,
           dependency_chain: dependency_chain
         } = file
       ) do
    metadata =
      metadata
      |> Map.put(:input_file, input_file)
      |> Map.put(:dependency_chain, dependency_chain)

    Renderer.create(%{file | metadata: metadata})
    |> apply(:render, [])
  end
end
