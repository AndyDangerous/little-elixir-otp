defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec
  # defstruct sup: nil, worker_sup: nil, size: nil, workers: nil, mfa: nil

  defmodule State do
    # defstruct sup: nil, size: nil, mfa: nil
    defstruct sup: nil, worker_sup: nil, size: nil, workers: nil, mfa: nil, monitors: nil
  end

  ## API

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], [name: __MODULE__])
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker) do
    GenServer.cast(__MODULE__, {:checkin, worker})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  ## Calbacks

  def init([sup, pool_config]) when is_pid(sup) do
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
  end

  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end
  def init([{:mfa, mfa}|rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  def init([_|rest], state) do
    init(rest, state)
  end

  def init([], state) do
    send(self, :start_worker_supervisor)
    {:ok, state}
  end

  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}
      [] -> 
      {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, {length(state.workers), :ets.info(state.monitors, :size)}, state}
  end

  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid|workers]}}
      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_supervisor, %State{} = state) do
    {:ok, worker_sup} = Supervisor.start_child(state.sup, supervisor_spec(state.mfa))
    workers = prepopulate(state.size, worker_sup)

    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  ## Helper Functions

  defp supervisor_spec(mfa) do
    opts = [restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [mfa], opts)
  end

  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end

  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, sup, workers) do
    prepopulate(size - 1, sup, [new_worker(sup) | workers])
  end

  defp new_worker(sup) do
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    worker
  end
end
