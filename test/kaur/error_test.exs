defmodule Kaur.ErrorTest do
  use ExUnit.Case
  use Kaur.Error

  defmodule E do
    @behaviour Kaur.Error

    defstruct [:__exception__, :__kaur_error__, :message, :next]

    def exception(error), do: error
    def message(error), do: error.message
    def next(error), do: error.next
  end

  test "kaur_error?: when the parameter is a kaur error" do
    error = error("dummy")
    assert Kaur.Error.kaur_error?(error) == true
  end

  test "kaur_error?: when the parameter is not a kaur error" do
    exception = %RuntimeError{}
    assert Kaur.Error.kaur_error?(exception) == false
  end

  test "next: when the parameter has a next error" do
    error0 = error(0)
    error1 = Kaur.Error.push(error(1), error0)
    assert Kaur.Error.next(error1) == error0
  end

  test "next: when the parameter has not a next error" do
    error0 = error(0)
    assert Kaur.Error.next(error0) == :empty
  end

  test "push: in well order" do
    error0 = error(0)
    error1 = Kaur.Error.push(error(1), error0)

    assert error1 == %Kaur.ErrorTest.E{
             __exception__: true,
             __kaur_error__: true,
             message: 1,
             next: %Kaur.ErrorTest.E{
               __exception__: true,
               __kaur_error__: true,
               message: 0,
               next: :empty
             }
           }
  end

  test "trace: trace returns a singleton with a single error" do
    error0 = error(0)
    assert Kaur.Error.trace(error0) == [error0]
  end

  test "trace: ordered trace with more than one error" do
    error0 = error(0)
    error1 = error(1)
    error2 = Kaur.Error.push(error1, error0)
    assert Kaur.Error.trace(error2) == [error1, error0]
  end

  def error(message, next \\ :empty) do
    %E{__exception__: true, __kaur_error__: true, message: message, next: next}
  end
end
