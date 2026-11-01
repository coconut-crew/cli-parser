# Agent Instructions

## typechecking

- Types you write should be worthy of trust. keep them accurate, useful, and semantically honest:
  - Avoid use of the `any` type unless explicitly asked to use it.
  - Check code with `lute check <paths...>`
  - Lint code with `lute lint <paths...>`

## verifying code

- Always check style/lint/tests, even if one (or more) have outstanding issues.
- Style code with `stylua ./`
- Run tests:
  - full; `lute test`
  - suite; `lute test -s <match>`
  - case; `lute test -c <match>`

## AI-generated code markers

- Add `-- ai generated code` at the top of scripts you add autonomously.
- Add the following comment immediately above functions you implement:

  ```luau
  --[=[
  	ai generated implementation
  ]=]
  ```
