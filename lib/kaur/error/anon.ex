defmodule Kaur.Error.Anon do
  @moduledoc """
  Anonymous structure for errors from exceptions
  """
  import Kernel, except: [inspect: 1]

  @behaviour Kaur.Error

  defstruct [:__exception__, :__kaur_error__, :exception, :message, :next]

  def exception(error), do: error.exception
  def message(error), do: error.message
  def next(error), do: error.next

  defimpl Inspect, for: __MODULE__ do
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

  @doc """
  Takes an elixir exception and returns a `Kaur.Error.Anon` struct.

      iex> Kaur.Error.Anon.from_exception(%RuntimeError{})
      %Kaur.Error.Anon{
        exception: %RuntimeError{message: "runtime error"},
        message: "runtime error",
        next: :empty
      }
  """
  @spec from_exception(term) :: Kaur.Error.t()
  def from_exception(%module{__exception__: true} = exception) do
    %__MODULE__{
      __exception__: true,
      __kaur_error__: true,
      exception: exception,
      message: module.message(exception),
      next: :empty
    }
  end
end
