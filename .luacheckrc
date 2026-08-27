std = "lua51"

globals = {
  "love",
}

files = {
  ["src/core/"] = {
    globals = {},
  },
  ["tests/"] = {
    globals = {
      "describe",
      "it",
      "before_each",
      "after_each",
      "pending",
    },
  },
}