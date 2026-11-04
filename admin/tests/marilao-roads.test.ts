import { test } from "node:test";
import assert from "node:assert/strict";
import { catalogueRoad, marilaoRoadChoices, marilaoRoads } from "../src/lib/marilao-roads";

test("Marilao directory contains real attributed named road sections with valid IDs and coordinates", () => {
  assert.ok(marilaoRoads.length >= 450);
  assert.equal(new Set(marilaoRoads.map(road => road.id)).size, marilaoRoads.length);
  assert.ok(marilaoRoads.some(road => /MacArthur/i.test(road.name)));
  for (const road of marilaoRoads) {
    assert.match(road.id, /^[a-f0-9]{8}-[a-f0-9]{4}-5[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/);
    assert.ok(road.latitude > 14.6 && road.latitude < 14.9);
    assert.ok(road.longitude > 120.8 && road.longitude < 121.2);
    assert.ok(road.osmWayIds.length > 0);
    assert.equal(catalogueRoad(road.id)?.id, road.id);
  }
  assert.equal(catalogueRoad("not-a-catalogue-id"), undefined);
});

test("existing Marilao roads retain their IDs and replace exact catalogue duplicates", () => {
  const road = marilaoRoads[0];
  const options = marilaoRoadChoices([
    { id:"existing-id", name:road.name, locality:"Marilao, Bulacan" },
    { id:"outside-id", name:"Outside road", locality:"Cebu City" },
  ]);
  assert.ok(options.some(option => option.value === "existing-id"));
  assert.ok(!options.some(option => option.value === road.id));
  assert.ok(!options.some(option => option.value === "outside-id"));
  assert.equal(options.length, marilaoRoads.length);
});
