defmodule Kaur.Error.AnonTest do
  use ExUnit.Case
  use Kaur.Error

  test "from_exception: returns a kaur error" do
    exception = %RuntimeError{}
    error = Kaur.Error.Anon.from_exception(exception)
    assert Kaur.Error.kaur_error?(error) == true
  end

  test "from_exception: save the original exception in the :exception field" do
    exception = %RuntimeError{}
    error = Kaur.Error.Anon.from_exception(exception)
    assert error.exception == exception
  end
end
