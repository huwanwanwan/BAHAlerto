import { test } from "node:test";
import assert from "node:assert/strict";
import { geocodeCenter } from "../src/lib/geocoding";
import { centerInputSchema, saveSchema } from "../src/lib/validation";

const match = { lat: 14.7589, lon: 120.9531, country_code: "ph", result_type: "amenity", rank: { confidence: 0.95 } };
const requestFor = (results: unknown[]): typeof fetch => async () => Response.json({ results });

test("geocodes a Philippine facility and sends only name/address to the approved API", async () => {
  const request: typeof fetch = async (input, init) => {
    const url = new URL(String(input));
    assert.equal(url.origin, "https://api.geoapify.com");
    assert.equal(url.searchParams.get("text"), "Center, Street, Marilao");
    assert.equal(url.searchParams.get("filter"), "countrycode:ph");
    assert.equal(init?.cache, "no-store");
    return Response.json({ results: [match] });
  };
  assert.deepEqual(await geocodeCenter("Center", "Street, Marilao", { apiKey: "test-key", request }), { latitude: match.lat, longitude: match.lon });
});

test("rejects vague, ambiguous, out-of-country and malformed matches", async () => {
  for (const results of [[], [{ ...match, result_type: "city" }], [{ ...match, rank: { confidence: 0.5 } }], [match, match], [{ ...match, country_code: "us" }], [{ ...match, lat: 100 }]]) {
    await assert.rejects(geocodeCenter("Center", "Address", { apiKey: "test-key", request: requestFor(results) }));
  }
});

test("missing configuration and provider failures never expose the API key", async () => {
  await assert.rejects(geocodeCenter("Center", "Address", { apiKey: "" }), /not configured/);
  const request: typeof fetch = async () => { throw new Error("secret-key in URL"); };
  await assert.rejects(geocodeCenter("Center", "Address", { apiKey: "secret-key", request }), error => error instanceof Error && !error.message.includes("secret-key"));
  await assert.rejects(geocodeCenter("Center", "Address", { apiKey: "test", request: async () => new Response(null, { status: 429 }) }), /unavailable/);
});

test("center form needs no coordinates; database payload still requires valid coordinates", () => {
  const center = { kind: "center", name: "Center", address: "Street, Marilao", contact: "09171234567", operational_details: "Contact for availability", verified_at: "2026-11-04T00:00:00Z", published: "true", archived: "false" };
  assert.equal(centerInputSchema.safeParse(center).success, true);
  assert.equal(saveSchema.safeParse(center).success, false);
  assert.equal(saveSchema.safeParse({ ...center, latitude: match.lat, longitude: match.lon }).success, true);
});
