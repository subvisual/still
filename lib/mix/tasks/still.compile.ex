defmodule Mix.Tasks.Still.Compile do
  use Mix.Task

  @config_key :compilation_task

  @doc false
  def run(_) do
    # TO BE FIXED
    Mix.Task.run("compile")
    Mix.Task.run("app.start")

    Application.put_env(:still, @config_key, true)
    Application.put_env(:still, :url_fingerprinting, true)
    Application.put_env(:still, :dev_layout, false)

    Still.Compiler.Compile.run()
  end

  @spec config_key :: :compilation_task
  def config_key, do: @config_key
end
