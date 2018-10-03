defmodule BlackBoxMe do
  defp state_functions(core) do
    quote do
      def set_state(state) do
        Process.put(unquote(core), state)
      end

      def get_state do
        Process.get(unquote(core))
      end
    end
  end

  defp create_wrapper_function({func_name, arity}, core) do
    args = Macro.generate_arguments(arity - 1, nil)

    quote do
      def unquote(func_name)(unquote_splicing(args)) do
        state = get_state()

        case :erlang.apply(unquote(core), unquote(func_name), unquote(args) ++ [state]) do
          {:ok, side_effects, new_state} ->
            set_state(new_state)
            {:ok, side_effects}

          {:ok, new_state} ->
            set_state(new_state)
            :ok

          {{:error, error}, new_state} ->
            set_state(new_state)
            {:error, error}

          unexpected ->
            IO.puts(
              "unexpected output #{inspect(unquote(func_name)(unquote_splicing(args)))} :: #{inspect(unexpected)}"
            )

            :erlang.error({:badreturn, unexpected})
        end
      end
    end
  end

  defmacro create({:__aliases__, _, list_atoms}, {:__aliases__, _, dest}) do
    IO.puts("BlackBoxMe create:")
    core = Module.concat(list_atoms)
    module_name = Module.concat(dest)

    contents =
      :functions
      |> core.__info__()
      |> Enum.filter(fn {function_name, _} -> !MapSet.member?(MapSet.new([:__info__, :__struct__]), function_name) end)
      |> Enum.map(&create_wrapper_function(&1, core))
      |> List.insert_at(0, state_functions(core))

    {:module, _, _, _} = Module.create(module_name, contents, Macro.Env.location(__ENV__))
    []
  end
end

defmodule PufPuf do
  def save_num(number,state), do: {:ok, [number | state]}
  def save_num(number), do: :ok #{:ok,[number | state]} 
end
