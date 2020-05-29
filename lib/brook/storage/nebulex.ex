defmodule Brook.Storage.Nebulex do
  @moduledoc """
  Implements the `Brook.Storage` behaviour for `Nebulex.Cache`.
  """
  use GenServer

  alias Brook.Config

  @behaviour Brook.Storage

  @impl Brook.Storage
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl Brook.Storage
  def delete(instance, collection, key) do
    with_cache(instance, fn cache ->
      cache.transaction(fn ->
        cache.get_and_update(view_collection(instance, collection), fn original_collection ->
          new_state = Map.delete(default_collection(original_collection), key)
          {original_collection, new_state}
        end)

        cache.get_and_update(event_collection(instance, collection), fn original_collection ->
          new_state = Map.delete(default_collection(original_collection), key)
          {original_collection, new_state}
        end)

        :ok
      end)
    end)
  end

  @impl Brook.Storage
  def get(instance, collection, key) do
    with_collection(instance, view_collection(instance, collection), fn collection ->
      {:ok, Map.get(collection, key)}
    end)
  end

  @impl Brook.Storage
  def get_all(instance, collection) do
    with_collection(instance, view_collection(instance, collection), fn collection ->
      {:ok, collection}
    end)
  end

  @impl Brook.Storage
  def get_events(instance, collection, key) do
    {:ok, collection_events(instance, collection, key)}
  end

  @impl Brook.Storage
  def get_events(instance, collection, key, event_type) do
    events =
      instance
      |> collection_events(collection, key)
      |> Enum.filter(fn %{type: type} -> type == event_type end)

    {:ok, events}
  end

  defp collection_events(instance, collection, key) do
    with_collection(instance, event_collection(instance, collection), fn collection ->
      collection
      |> Map.get(key, [])
      |> sort_events()
    end)
  end

  @impl Brook.Storage
  def persist(instance, event, collection, key, value) do
    with_cache(instance, fn cache ->
      cache.transaction(fn ->
        # Update view
        cache.get_and_update(view_collection(instance, collection), fn original_collection ->
          {original_collection, Map.put(default_collection(original_collection), key, value)}
        end)

        # Update event log
        cache.get_and_update(event_collection(instance, collection), fn original_collection ->
          collection = default_collection(original_collection)
          items = [event | Map.get(collection, key, [])]
          {original_collection, Map.put(collection, key, items)}
        end)

        :ok
      end)
    end)
  end

  ################################################################################
  # SERVER
  ################################################################################
  @impl GenServer
  def init([instance: instance, cache: cache] = opts) do
    Config.put(instance, :cache, cache)
    {:ok, opts}
  end

  ################################################################################
  # PRIVATE
  ################################################################################
  defp view_collection(instance, collection), do: {:view, instance, collection}
  defp event_collection(instance, collection), do: {:events, instance, collection}

  defp with_collection(instance, collection, fun) do
    with_cache(instance, fn cache ->
      collection
      |> cache.get()
      |> default_collection()
      |> fun.()
    end)
  end

  defp with_cache(instance, fun) do
    case Config.get(instance, :cache) do
      {:ok, cache} ->
        fun.(cache)

      _other ->
        raise not_initialized_exception()
    end
  end

  defp default_collection(nil), do: %{}
  defp default_collection(collection), do: collection

  defp sort_events(events) do
    Enum.sort_by(events, fn event -> event.create_ts end)
  end

  defp not_initialized_exception() do
    Brook.Uninitialized.exception(message: "#{__MODULE__} is not yet initialized!")
  end
end
