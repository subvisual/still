defmodule Still.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Still.Compiler.ErrorCache

      import Still.Utils

      setup do
        Application.put_env(:still, :pass_through_copy, [])

        Still.Utils.clean_output_dir()

        {:ok, _} = ErrorCache.start_link(%{})

        :ok
      end
    end
  end
end
