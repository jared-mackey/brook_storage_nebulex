# Brook Storage Nebulex

A `Brook.Storage` implementation using [Nebulex](https://github.com/cabol/nebulex)

## Installation

```elixir
def deps do
  [
    {:brook_storage_nebulex, "~> 0.1.0"}
  ]
end
```

# Usage

Set the storage to be the Nebulex storage driver.

```elixir
config :my_app, :brook,
  instance: :default,
  driver: [
    module: Brook.Driver.Json,
    init_arg: []
  ],
  handlers: [MyApp.Event.Handler],
  storage: [
    module: Brook.Storage.Nebulex,
    init_arg: [
      cache: MyApp.Event.Cache
    ]
  ]
```

Ensure your cache is started in your supervision tree before starting brook. The storage driver should work with any type of Nebulex cache. Caches are safe to share across brook instances.
