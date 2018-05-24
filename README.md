# Kaur.Error

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kaur_error` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kaur_error, "~> 0.1.0"}
  ]
end
```

## Usage

`{:ok, value}` and `{:error, reason}` is a common pattern in Erlang
and Elixir.
While we usually spend a lot of time shaping the `values` (with structs for
instance), the organization of `reasons` however may sometimes look like
a wild jungle and the ways of reporting errors in Elixir has already been the
subject of numerous blog posts (see [1], [2], [3]).
A similar problem [occured in the Haskell community](http://article.gmane.org/gmane.comp.lang.haskell.libraries/6382)
over 11 years ago and Donald Bruce Stewart wrote this remark
after reading a "[8 ways to report errors in Haskell](http://www.randomhacks.net.s3-website-us-east-1.amazonaws.com/2007/03/10/haskell-8-ways-to-report-errors/)"
blog post.

> we need to standardise/recommend a small set of methods for
> library error handling.

The `Kaur.Error` module aims to help the programmer dealing with
errors in Elixir by providing the following features:

- **Organization**: we want to rely on structs explicitely
  defined in the code as we do with exceptions instead of a keyword list or a map.
- **Pattern matching**: we want to be able to pattern match over the previous errors.
  This is done by the use of nested structs.
- **Accumulative errors**: we want to be able to accumulate errors.
  This is done by the `:next` field in `Kaur.Error` and the
  `Kaur.Error.push/2` function that allows us to chain errors.
- **Kaur.Result**: `Kaur.Error` interacts very well with
  the [kaur result](https://github.com/fewlinesco/kaur_result) library.

[1]: https://elixiroutlaws.com/1
[2]: https://diveintoelixir.io/graceful-error-handling-in-elixir-c611106e140c
[3]: https://michal.muskala.eu/2017/02/10/error-handling-in-elixir-libraries.html

### Example


In the following example we use the [kaur result](https://github.com/fewlinesco/kaur_result)
library for the sake of clarity.

```elixir
defmodule Data do
  alias Kaur.Result
  use Kaur.Error

  defmodule Validate do
    deferror NegativeAgeError, [:message, :value]

    def do_validate(%{age: age}) when age >= 0, do: Result.ok(%{age: age})

    def do_validate(%{age: age}) do
      Result.error(%NegativeAgeError{message: "should be positive", value: age})
    end
  end

  defmodule User do
    defstruct [:age]

    deferror CreateError, message: "cannot create user"
    deferror UpdateError, message: "cannot update user"

    def do_create(%{age: age}) do
      %{age: age}
      |> Validate.do_validate()
      |> Result.map(&%__MODULE__{age: &1.age})
      |> Result.map_error(&Kaur.Error.push(%CreateError{}, &1))
    end

    def do_update(%User{} = user, %{age: age}) do
      %{age: age}
      |> Validate.do_validate()
      |> Result.map(&%{user | age: &1.age})
      |> Result.map_error(&Kaur.Error.push(%UpdateError{}, &1))
    end
  end
end
```

Here is an example of a simple workflow and its returned value.

```elixir
%{age: -2}
|> Data.User.do_create()
|> Result.and_then(&Data.User.do_update(&1, %{age: 3}))
```

```elixir
{:error,
 %Data.User.CreateError{
   message: "cannot create user",
   next: %Data.Validate.NegativeAgeError{
     message: "should be positive",
     value: -2,
     next: :empty
   }
 }}
```

## Code of Conduct

By participating in this project, you agree to abide by its [CODE OF CONDUCT](CODE_OF_CONDUCT.md).

## Contributing

You can see the specific [CONTRIBUTING](CONTRIBUTING.md) guide.

## License

Kaur.Result is released under [The MIT License (MIT)](https://opensource.org/licenses/MIT).
