defmodule Kaur.Error do
  @moduledoc """
  Error shaping library for Elixir
  """
  import Kernel, except: [inspect: 1]
  import Inspect.Algebra

  defmacrop aux(map, open, sep, close, opts) do
    bounded_version = Version.parse!("1.6.0")
    actual_version = Version.parse!(System.version())

    if Version.compare(actual_version, bounded_version) in [:gt, :eq] do
      quote bind_quoted: [
              open: open,
              map: map,
              close: close,
              opts: opts,
              sep: sep
            ] do
        container_doc(
          open,
          map,
          close,
          opts,
          traverse_fun(map, opts),
          separator: sep,
          break: :strict
        )
      end
    else
      quote bind_quoted: [
              open: open,
              map: map,
              close: close,
              opts: opts,
              sep: sep
            ] do
        surround_many(open, map, close, opts, traverse_fun(map, opts), sep)
      end
    end
  end

  @typedoc "The error type"
  @type t :: %{
          required(:__struct__) => module,
          required(:__exception__) => true,
          required(:__kaur_error__) => true,
          optional(atom) => any
        }

  @callback exception(term) :: Exception.t()
  @callback message(t) :: String.t()
  @callback next(t) :: t | :empty

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros
    end
  end

  @doc ~S"""
  Defines an error.

  The `Error` behaviour requires three functions to be implemented:
    * `exception/1`
    * `message/1`
    * `next/1`

  Since errors are exceptions and structs, the APIs supported by `defstruct/1` and
  `defexception` are also available in `deferror/1`.

      defmodule MyAppError do
        deferror Error.DivideByZero, message: "cannot divide by zero"

        def divide(m,n) when n = 0, do: Result.error(%Error.DivideByZero{})
        def divide(m,n), do: Result.ok(m / n)
      end
  """
  defmacro deferror(name, fields) do
    quote do
      defmodule unquote(name) do
        @behaviour Kaur.Error

        struct =
          defstruct(
            [__exception__: true, __kaur_error__: true, next: :empty] ++
              unquote(fields)
          )

        if Map.has_key?(struct, :message) do
          def message(error), do: error.message

          defoverridable message: 1

          def exception(msg) when is_binary(msg) do
            exception(message: msg)
          end
        end

        def exception(args) when is_list(args) do
          struct = __struct__()

          {valid, invalid} =
            Enum.split_with(args, fn {k, _} -> Map.has_key?(struct, k) end)

          case invalid do
            [] ->
              :ok

            _ ->
              IO.warn(
                "the following fields are unknown when raising " <>
                  "#{inspect(__MODULE__)}: #{inspect(invalid)}. " <>
                  "Please make sure to only give known fields when raising " <>
                  "or redefine #{inspect(__MODULE__)}.exception/1 to " <>
                  "discard unknown fields. Future Elixir versions will raise on " <>
                  "unknown fields given to raise/2"
              )
          end

          Kernel.struct!(struct, valid)
        end

        defoverridable exception: 1

        def next(error), do: error.next

        defimpl Inspect, for: unquote(name) do
          def inspect(%module{__kaur_error__: true} = struct, opts) do
            pruned =
              :maps.remove(
                :__kaur_error__,
                :maps.remove(:__exception__, :maps.remove(:__struct__, struct))
              )

            colorless_opts = %{opts | syntax_colors: []}

            Kaur.Error.inspect(
              pruned,
              Inspect.Atom.inspect(module, colorless_opts),
              opts
            )
          end
        end
      end
    end
  end

  @doc """
  Returns `true` if the given `term` is a kaur error or false otherwise.
  """
  @spec kaur_error?(t) :: boolean
  def kaur_error?(term)
  def kaur_error?(%_{__kaur_error__: true}), do: true
  def kaur_error?(_), do: false

  @doc """
  Returns the next error or `:empty` if there is not.
  """
  @spec next(t) :: t | :empty
  def next(%module{__kaur_error__: true} = error), do: module.next(error)

  @doc """
  Adds the `error1` element at the top of `error2`.

      iex> defmodule Error do
      ...>   deferror A, message: "a"
      ...>   deferror B, message: "b"
      ...> end
      ...> Kaur.Error.push(%Error.A{}, %Error.B{})
      %Error.A{
         message: "a",
         next: %Error.B{
           message: "b",
           next: :empty
         }
      }
  """
  @spec push(t, t) :: t
  def push(%{__kaur_error__: true} = error1, error2) do
    %{error1 | next: error2}
  end

  @doc """
  Takes an error and returns its corresponding trace.

  It recursively calls `trace` on the value returned by applying
  `next` on this error.
  The trace ends when the value returned by applying the `next` callback
  is `:empty` or is not a kaur error.

      iex> defmodule Error do
      ...>   deferror A, message: "a"
      ...>   deferror B, message: "b"
      ...> end
      ...> errors = Kaur.Error.push(%Error.A{}, %Error.B{})
      ...> Kaur.Error.trace(errors)
      [%Error.A{message: "a", next: :empty}, %Error.B{message: "b", next: :empty}]

  """
  @spec trace(t) :: list(t)
  def trace(%module{__kaur_error__: true} = error) do
    case module.next(error) do
      :empty ->
        [error]

      e ->
        [%{error | next: :empty} | trace(e)]
    end
  end

  def trace(e), do: [e]

  @doc false
  def inspect(map, name, opts) do
    {next_error, new_map} = Map.pop(map, :next)
    map = :maps.to_list(new_map) ++ [next: next_error]
    open = color("%" <> name <> "{", :map, opts)
    sep = color(",", :map, opts)
    close = color("}", :map, opts)
    aux(map, open, sep, close, opts)
  end

  defp to_map({key, value}, opts, sep) do
    concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
  end

  defp traverse_fun(list, opts) do
    if Inspect.List.keyword?(list) do
      &Inspect.List.keyword/2
    else
      sep = color(" => ", :map, opts)
      &to_map(&1, &2, sep)
    end
  end
end
