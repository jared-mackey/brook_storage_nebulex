defmodule Cache do
  use Nebulex.Cache,
    otp_app: :brook_storage_nebulex,
    adapter: Nebulex.Adapters.Local
end

defmodule Brook.Storage.NebulexTest do
  use ExUnit.Case
  alias Brook.Storage.Nebulex

  @instance :nebulex_test

  setup :start_storage_nebulex

  describe "persist/4" do
    test "will save the key/value in a collection" do
      event = Brook.Event.new(type: "create", author: "testing", data: "data")
      Nebulex.persist(@instance, event, "people", "key1", %{"one" => 1})

      assert %{"key1" => %{"one" => 1}} == Cache.get!({:view, @instance, "people"})
    end

    test "allows unique combinations of collection and key" do
      event1 = Brook.Event.new(type: "create", author: "testing", data: %{"a" => 1})
      event2 = Brook.Event.new(type: "create", author: "testing", data: %{"b" => 2})

      :ok = Nebulex.persist(@instance, event1, "collection-1", "key", event1.data)
      :ok = Nebulex.persist(@instance, event2, "collection-2", "key", event2.data)

      assert %{"key" => %{"a" => 1}} == Cache.get({:view, @instance, "collection-1"})
      assert %{"key" => %{"b" => 2}} == Cache.get({:view, @instance, "collection-2"})
    end

    test "will append the event to the events list" do
      event1 = Brook.Event.new(author: "bob", type: "create", data: %{"one" => 1})
      event2 = Brook.Event.new(author: "bob", type: "update", data: %{"one" => 1, "two" => 2})

      :ok = Nebulex.persist(@instance, event1, "people", "key1", event1.data)
      :ok = Nebulex.persist(@instance, event2, "people", "key1", event2.data)

      assert %{"key1" => %{"one" => 1, "two" => 2}} == Cache.get!({:view, @instance, "people"})
      assert %{"key1" => [event2, event1]} == Cache.get!({:events, @instance, "people"})
    end
  end

  describe "get/2" do
    test "will return the value persisted to postgres" do
      event = Brook.Event.new(type: "create", author: "testing", data: :data1)
      :ok = Nebulex.persist(@instance, event, "people", "key1", %{name: "joe"})

      assert {:ok, %{name: "joe"}} == Nebulex.get(@instance, "people", "key1")
    end
  end

  describe "get_events/2" do
    test "returns all events for key" do
      event1 = Brook.Event.new(author: "steve", type: "create", data: %{"one" => 1}, create_ts: 0)

      event2 =
        Brook.Event.new(
          author: "steve",
          type: "update",
          data: %{"one" => 1, "two" => 2},
          create_ts: 1
        )

      :ok = Nebulex.persist(@instance, event1, "people", "key1", event1.data)
      :ok = Nebulex.persist(@instance, event2, "people", "key1", event2.data)

      assert {:ok, [event1, event2]} == Nebulex.get_events(@instance, "people", "key1")
    end

    test "returns only events matching type" do
      event1 = Brook.Event.new(author: "steve", type: "create", data: %{"one" => 1}, create_ts: 0)

      event2 =
        Brook.Event.new(
          author: "steve",
          type: "update",
          data: %{"one" => 1, "two" => 2},
          create_ts: 1
        )

      event3 = Brook.Event.new(author: "steve", type: "create", data: %{"one" => 1}, create_ts: 2)

      :ok = Nebulex.persist(@instance, event1, "people", "key1", event1.data)
      :ok = Nebulex.persist(@instance, event2, "people", "key1", event2.data)
      :ok = Nebulex.persist(@instance, event3, "people", "key1", event3.data)

      assert {:ok, [event1, event3]} == Nebulex.get_events(@instance, "people", "key1", "create")
    end
  end

  describe "get_all/1" do
    test "returns all the values in a collection" do
      event = Brook.Event.new(type: "create", author: "testing", data: "data")
      :ok = Nebulex.persist(@instance, event, "people", "key1", "value1")
      :ok = Nebulex.persist(@instance, event, "people", "key2", "value2")
      :ok = Nebulex.persist(@instance, event, "people", "key3", "value3")

      expected = %{"key1" => "value1", "key2" => "value2", "key3" => "value3"}

      assert {:ok, expected} == Nebulex.get_all(@instance, "people")
    end

    test "returns empty map when no data available" do
      assert {:ok, %{}} == Nebulex.get_all(@instance, "jerks")
    end
  end

  describe "delete/2" do
    test "deletes view and event entries in nebulex" do
      event = Brook.Event.new(type: "create", author: "testing", data: "data1")
      :ok = Nebulex.persist(@instance, event, "people", "key1", "value1")
      assert {:ok, "value1"} == Nebulex.get(@instance, "people", "key1")

      :ok = Nebulex.delete(@instance, "people", "key1")
      assert :ok = Nebulex.delete(@instance, "people", "key1")
      assert {:ok, nil} == Nebulex.get(@instance, "people", "key1")
      assert {:ok, []} == Nebulex.get_events(@instance, "people", "key1")
    end
  end

  defp start_storage_nebulex(_context) do
    registry_name = Brook.Config.registry(@instance)
    start_supervised({Registry, name: registry_name, keys: :unique})
    start_supervised({Cache, []})
    start_supervised({Nebulex, instance: @instance, cache: Cache})

    :ok
  end
end
