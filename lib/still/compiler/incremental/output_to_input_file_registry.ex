defmodule Still.Compiler.Incremental.OutputToInputFileRegistry do
  @moduledoc """
  Keeps track of which input file generates each output file.
  It's used to identify which file needs to be compiled when there's a request from the browser.
  """

  import Still.Utils

  @doc """
  Registers an input and output pair.
  """
  @spec register(binary(), binary()) :: any()
  def register(input_file, output_file) do
    Registry.register(
      __MODULE__,
      output_file |> Still.Utils.get_output_path(),
      input_file
    )
  end

  @doc """
  Compiles the input files for the given output.
  """
  @spec recompile(binary()) :: any()
  def recompile(output_file) do
    Registry.dispatch(__MODULE__, output_file, fn entries ->
      for {_pid, input_file} <- entries,
          do: compile_file(input_file)
    end)
  end

  @doc """
  Returns a list of the registered input files for the given output.
  """
  @spec lookup(binary()) :: list({pid(), binary()})
  def lookup(output_file) do
    Registry.lookup(__MODULE__, output_file)
  end
end
