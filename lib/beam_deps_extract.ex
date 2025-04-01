defmodule BeamDepsExtract do
  @moduledoc """
  Documentation for `BeamDepsExtract`.
  """

  use Application

  @switches [path: :string]

  ##############################################################################
  # Security Disclaimer:
  # Both rebar3 and mix use Code for Configuration & Lockfiles.
  # To read them, they are executed. Do not run on untrusted code and
  # appropriate sandboxing.
  ##############################################################################

  @spec start(any(), any()) :: no_return()
  def start(_start_type, _start_args) do
    args = read_argv()

    info = cond do
      args[:path] |> Path.join("mix.exs") |> File.exists?() -> dump_mix(args)
      args[:path] |> Path.join("rebar.config") |> File.exists?() -> dump_rebar(args)
      # args[:path] |> Path.join("erlang.mk") |> File.exists?() -> dump_erlang_mk(args)
      true -> raise "not supported"
    end

    info
    |> make_json_compatible()
    |> Jason.encode!()
    |> IO.puts

    System.halt(0)
  end

  defp dump_mix(args) do
    Mix.Project.in_project(:app_name, args[:path], fn _module ->
      %{
        type: :mix,
        mix_config: Mix.Project.config(),
        deps_tree: Mix.Project.deps_tree(),
        deps_scms: Mix.Project.deps_scms(),
        # Careful: internal API used!
        lockfile: Mix.Dep.Lock.read()
      }
    end)
  end

  defp dump_rebar(args) do
    # TODO: Use :rebar3 as library
    %{
      config: args[:path] |> Path.join("rebar.config") |> eval_erlang_file(),
      lock: args[:path] |> Path.join("rebar.lock") |> eval_erlang_file(),
    }
  end

  defp make_json_compatible(data) when is_function(data), do: inspect(data)
  defp make_json_compatible(data) when is_map(data), do: Map.new(data, &{make_json_compatible(elem(&1, 0)), make_json_compatible(elem(&1, 1))})
  defp make_json_compatible(data) when is_list(data), do: Enum.map(data, &make_json_compatible/1)
  defp make_json_compatible(data) when is_tuple(data), do: data |> Tuple.to_list() |> make_json_compatible()
  defp make_json_compatible(data), do: data

  defp eval_erlang_file(path) do
    if File.exists?(path) do
      path |> String.to_charlist() |> :file.consult()
    end
  end

  defp read_argv do
    argv = Burrito.Util.Args.argv()
    {parsed, []} = OptionParser.parse!(argv, strict: @switches)

    Map.merge(%{path: File.cwd!()}, Map.new(parsed))
  end
end
