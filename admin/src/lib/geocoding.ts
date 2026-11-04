import { z } from "zod";

const responseSchema = z.object({ results: z.array(z.object({
  lat: z.number().min(-90).max(90), lon: z.number().min(-180).max(180),
  country_code: z.string(), result_type: z.string(),
  rank: z.object({ confidence: z.number().min(0).max(1) }),
})) });

export async function geocodeCenter(name: string, address: string, {
  apiKey = process.env.GEOAPIFY_API_KEY,
  request = fetch,
}: { apiKey?: string; request?: typeof fetch } = {}) {
  if (!apiKey) throw new Error("Automatic location lookup is not configured. Ask the site owner to set GEOAPIFY_API_KEY.");
  const url = new URL("https://api.geoapify.com/v1/geocode/search");
  url.search = new URLSearchParams({ text: `${name}, ${address}`, filter: "countrycode:ph", format: "json", limit: "2", apiKey }).toString();
  let response: Response;
  try {
    response = await request(url, { signal: AbortSignal.timeout(10000), cache: "no-store" });
  } catch {
    throw new Error("Location lookup is unavailable. Please try saving again.");
  }
  if (!response.ok) throw new Error("Location lookup is unavailable. Please try saving again.");
  const parsed = responseSchema.safeParse(await response.json().catch(() => null));
  if (!parsed.success) throw new Error("Location lookup returned an invalid result. Please try again.");
  const [match, alternative] = parsed.data.results;
  if (!match || match.country_code !== "ph" || match.rank.confidence < 0.8 ||
      !["building", "amenity"].includes(match.result_type) ||
      (alternative && alternative.rank.confidence >= match.rank.confidence - 0.1)) {
    throw new Error("The center's exact location could not be identified. Use its official name and a complete street address, including the municipality.");
  }
  return { latitude: match.lat, longitude: match.lon };
}
