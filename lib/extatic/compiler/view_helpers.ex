defmodule Extatic.Compiler.ViewHelpers do
  import Extatic.Utils

  alias Extatic.Compiler
  alias Extatic.Compiler.ViewHelpers

  def include(file) do
    with {:ok, preprocessor} <- Compiler.Preprocessor.for(file),
         input_file <- get_input_path() |> Path.join(file),
         :ok <- Compiler.Context.push(input_file, nil, preprocessor),
         {:ok, content} <-
           input_file
           |> File.read!()
           |> Compiler.Content.compile(preprocessor) do
      content
    else
      _ -> ""
    end
  end

  def link(content, opts) do
    ViewHelpers.Link.render(content, opts)
  end
end
