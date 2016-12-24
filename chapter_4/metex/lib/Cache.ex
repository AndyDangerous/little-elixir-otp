defmodule Cache do
  use GenServer

  @name CACHE

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: @name])
  end

  def write(k, v) do
    GenServer.cast(@name, {:write, k, v})
  end

  def read do
    GenServer.call(@name, :read)
  end

  def read(key) do
    GenServer.call(@name, {:read, key})
  end

  def delete(key) do
    GenServer.cast(@name, {:delete, key})
  end

  def clear do
    GenServer.cast(@name, :clear)
  end

  def exist?(key) do
    GenServer.call(@name, {:exist?, key})
  end
   
  ## Server Callbacks

  def init(_args) do
    {:ok, %{}}
  end

  def handle_cast({:write, k, v}, state) do
    new_state = state
    |> Map.put(k, v)
    {:noreply, new_state}
  end

  def handle_cast({:delete, key}, state) do
    new_state = Map.delete(state, key)
    {:noreply, new_state}
  end

  def handle_cast(:clear, _state) do
    {:noreply, %{}}
  end

  def handle_call({:read, key}, _from, state) do
    {:reply, Map.fetch(state, key), state}
  end
  def handle_call(:read, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:exist?, key}, _from, state) do
    {:reply, Map.has_key?(state, key), state}
  end
end
