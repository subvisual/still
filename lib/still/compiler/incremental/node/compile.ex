defmodule Still.Compiler.Incremental.Node.Compile do
  @moduledoc """
  Compiles the contents of a `Still.Compiler.Incremental.Node`.

  First attempts a pass through copy of the file, in case it should be ignored.
  When this isn't successful, attempts a compilation via `Still.Compiler.File`,
  notifying any relevant subscribers of changes.
  """

  alias Still.SourceFile
  alias Still.Preprocessor

  alias Still.Compiler.{
    PassThroughCopy,
    ErrorCache,
    Incremental.OutputToInputFileRegistry,
    PreprocessorError
  }

  require Logger

  def run(input_file, run_type \\ :compile) do
    source_file =
      %SourceFile{
        input_file: input_file,
        dependency_chain: [input_file],
        run_type: run_type
      }
      |> do_run()

    ErrorCache.set({:ok, source_file})

    if source_file.output_file do
      OutputToInputFileRegistry.register(input_file, source_file.output_file)
    end

    source_file
  catch
    _, %PreprocessorError{} = error ->
      handle_error(error)
      raise error

    kind, payload ->
      error = %PreprocessorError{
        payload: payload,
        kind: kind,
        stacktrace: __STACKTRACE__,
        source_file: %SourceFile{input_file: input_file, run_type: :compile}
      }

      handle_error(error)
      raise error
  end

  def do_run(source_file) do
    case try_pass_through_copy(source_file) do
      :ok -> %{source_file | output_file: source_file.input_file}
      _ -> do_compile(source_file)
    end
  end

  defp try_pass_through_copy(source_file) do
    PassThroughCopy.try(source_file.input_file)
  end

  defp do_compile(source_file) do
    cond do
      should_be_ignored?(source_file.input_file) ->
        source_file

      true ->
        Preprocessor.run(source_file)
    end
  end

  defp should_be_ignored?(file) do
    Path.split(file) |> Enum.any?(&String.starts_with?(&1, "_"))
  end

  defp handle_error(error) do
    Logger.error(error)

    if Still.Utils.compilation_task?() do
      System.stop(1)
    else
      ErrorCache.set({:error, error})
    end
  end
end
