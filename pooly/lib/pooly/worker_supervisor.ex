defmodule Pooly.WorkerSupervisor do
  use Supervisor

  ## Client API

  def start_link({_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  ## Server Callbacks

  def init({module, function, args}) do
    worker_opts = [restart: :permanent,
                  function: function]

    children = [worker(module, args, worker_opts)]

    opts = [strategy: :simple_one_for_one,
            max_restarts: 5,
            max_seconds: 5]

    supervise(children, opts)
  end
end
