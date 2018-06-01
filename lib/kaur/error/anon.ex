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

  defimpl Inspect, for: Kaur.Error.Anon do
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
