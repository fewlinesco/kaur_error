defmodule KaurErrorTest do
  use ExUnit.Case
  doctest KaurError

  test "greets the world" do
    assert KaurError.hello() == :world
  end
end
