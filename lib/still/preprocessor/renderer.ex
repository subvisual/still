defmodule Still.Preprocessor.Renderer do
  @type ast :: {atom(), keyword(), list()}

  @callback compile(String.t(), [{atom(), any()}]) :: ast()

  @callback ast() :: ast()

  @optional_callbacks [ast: 0]

  alias Still.SourceFile

  defmacro __using__(opts) do
    quote do
      @behaviour unquote(__MODULE__)
      @preprocessor Keyword.fetch!(unquote(opts), :preprocessor)
      @extensions Keyword.fetch!(unquote(opts), :extensions)

      def create(%SourceFile{input_file: input_file, content: content, variables: variables}) do
        variables[:input_file]
        |> file_path_to_module_name()
        |> create_view_renderer(content, variables)
      end

      defp file_path_to_module_name(file) do
        name =
          Path.split(file)
          |> Enum.reject(&Enum.member?(["/" | @extensions], &1))
          |> Enum.map(&String.replace(&1, @extensions, ""))
          |> Enum.map(&String.replace(&1, "_", ""))
          |> Enum.map(&String.capitalize/1)

        Module.concat([@preprocessor | name])
      end

      defp create_view_renderer(name, content, variables) do
        compiled = compile(content, variables)

        module_variables =
          variables
          |> ensure_preprocessor()
          |> Map.to_list()

        renderer_ast =
          if Kernel.function_exported?(__MODULE__, :ast, 0) do
            ast()
          else
            []
          end

        ast =
          quote do
            @compile :nowarn_unused_vars

            unquote(user_view_helpers_asts())
            unquote(renderer_ast)

            use Still.Compiler.ViewHelpers, unquote(Macro.escape(module_variables))

            Enum.map(unquote(Macro.escape(variables)), fn {k, v} ->
              Module.put_attribute(__MODULE__, k, v)
            end)

            def render() do
              var!(unquote(Macro.var(:assigns, __MODULE__))) = unquote(Macro.escape(variables))
              _ = var!(unquote(Macro.var(:assigns, __MODULE__)))
              unquote(compiled)
            end
          end

        with {:module, mod, _, _} <- Module.create(name, ast, Macro.Env.location(__ENV__)) do
          mod
        end
      end

      defp user_view_helpers_asts do
        Application.get_env(:still, :view_helpers, [])
        |> Enum.map(fn module ->
          quote do
            import unquote(module)
          end
        end)
      end

      defp ensure_preprocessor(variables) do
        Map.put_new(variables, :preprocessor, @preprocessor)
      end
    end
  end
end
