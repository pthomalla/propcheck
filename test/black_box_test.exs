defmodule PropTest do

  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM.DSL

  def initial_state do
    IO.puts("initial_state set")
    #PufPufGs.set_state([])
    [] 
  end

  defcommand :save_num do
    def impl(number), do: PufPuf.save_num(number)#PufPufGs.save_num(number)
    def args(state) do
      let [num <-integer(1,1000)] do
        [num]
      end
    end
    def post(_state, [args], _ret) do
        args < 800
    end
    def next(model, [arg], _ret) do
      [arg | model]
    end
  end

  def state_core_property_test do
    forall cmds <- commands(__MODULE__) do
      trap_exit do
        %{history: history, result: result, state: _state, env: _env} = run_commands(cmds)
        history = List.first(history) |> elem(0) |> (fn value -> value[:model][:history] end).()

        (result == :ok)
        |> when_fail(
          (fn ->
             IO.puts("History: #{inspect(history)}")
             IO.puts("Result: #{inspect(result)}")
           end).()
        )
        |> aggregate(command_names(cmds))
      end
    end
  end

  property "quick test of property test", [numtests: 3] do
    IO.puts("black_box_test start")
    state_core_property_test()
  end
end
