defmodule Extatic.FileProcess do
  @doc """
  A FileProcess represents a file, or folder, that is processed
  individually. Each file has a list of subscriptions and subcribers. The
  subscriptions are the files included by the current file. The subscribers are
  the files that the current file includes. When the current file changes, it
  notifies the subscribers, and updates the subscriptions.

  A file can be compiled or rendered:

  * Compile - compiling a file means, most
  times, running it thorugh a preprocessor and writing to to the destination
  folder. 

  * Render - rendering a file means that the current file is being
  included by another file. Template files may return HTML and images could return a path.
  """

  use GenServer

  alias Extatic.Compiler
  alias __MODULE__.Compile

  def start_link(file: file) do
    GenServer.start_link(__MODULE__, %{file: file}, name: file |> String.to_atom())
  end

  def compile(pid) do
    GenServer.call(pid, :compile)
  end

  def render(pid, data, parent_file) do
    GenServer.call(pid, {:render, data, parent_file})
  end

  def add_subscription(pid, file) do
    GenServer.cast(pid, {:add_subscription, file})
  end

  def remove_subscriber(pid, file) do
    GenServer.call(pid, {:remove_subscriber, file})
  end

  @impl true
  def init(%{file: file}) do
    {:ok, %{file: file, subscribers: [], subscriptions: []}}
  end

  @impl true
  def handle_call(:compile, _from, state) do
    with result <- Compile.run(state) do
      {:reply, result, state}
    end
  end

  @impl true
  def handle_call({:render, data, parent_file}, _from, state) do
    subscribers = [parent_file | state.subscribers] |> Enum.uniq()

    {:reply, do_render(data, state), %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_call({:remove_subscriber, file}, _from, state) do
    subscribers = Enum.reject(state.subscribers, &(&1 == file))

    {:noreply, %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_cast({:add_subscription, file}, state) do
    subscriptions = [file | state.subscriptions] |> Enum.uniq()

    {:noreply, %{state | subscriptions: subscriptions}}
  end

  @impl true
  def handle_cast(:compile, state) do
    with _result <- Compile.run(state) do
      {:noreply, state}
    end
  end

  defp do_render(data, state) do
    Compiler.File.render(state.file, data)
  end
end
