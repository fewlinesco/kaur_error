%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.MaxLineLength, max_length: 80}
      ]
    }
  ]
}
