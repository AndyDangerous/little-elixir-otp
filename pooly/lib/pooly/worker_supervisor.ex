defmodule Pooly.WorkerSupervisor do
  use Supervisor

  ## Client API

  def start_link(server_pid, {_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, [server_pid, mfa])
  end

  ## Server Callbacks

  def init([server_pid, {module, function, args}]) do
    Process.link(server_pid)
    worker_opts = [restart: :permanent,
                  function: function]

    children = [worker(module, args, worker_opts)]

    opts = [strategy: :simple_one_for_one,
            max_restarts: 5,
            max_seconds: 5]

    supervise(children, opts)
  end
end
