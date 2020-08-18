defmodule Extatic.Compiler.File.Content do
  require Logger

  alias Extatic.FileProcess
  alias Extatic.Compiler.File.Frontmatter

  def compile(file, content, preprocessor, data \\ %{}) do
    with {:ok, template_data, content} <- Frontmatter.parse(content),
         data <- Map.merge(template_data, data) |> Map.put(:file_path, file),
         compiled <- render_template(content, preprocessor, data),
         compiled <- append_layout(compiled, data),
         compiled <- append_development_layout(compiled, preprocessor) do
      {:ok, compiled, data}
    end
  end

  defp append_layout(children, data = %{layout: _layout}) do
    with layout_data <-
           data
           |> Map.drop([:tag, :layout, :permalink, :file_path])
           |> Map.put(:children, children),
         {:ok, compiled, _} <-
           data[:layout]
           |> Extatic.FileRegistry.get_or_create_file_process()
           |> FileProcess.render(layout_data, data[:file_path]) do
      compiled
    end
  end

  defp append_layout(children, _), do: children

  case Mix.env() do
    :dev ->
      @dev_layout "priv/extatic/dev.slime"

      defp append_development_layout(content, preprocessor) do
        Application.app_dir(:extatic, @dev_layout)
        |> File.read!()
        |> render_template(preprocessor,
          children: content,
          file_path: @dev_layout
        )
      end

    _ ->
      defp append_development_layout(content, _preprocessor) do
        content
      end
  end

  defp render_template(content, preprocessor, variables) when is_map(variables) do
    render_template(content, preprocessor, variables |> Enum.to_list())
  end

  defp render_template(content, preprocessor, variables) do
    preprocessor.render(content, [{:collections, Extatic.Collections.all()} | variables])
  end
end
