import { copyFile, mkdir } from "node:fs/promises";
const output = new URL("../public/maplibre/", import.meta.url);
await mkdir(output, {recursive:true});
for (const file of ["maplibre-gl-worker.mjs", "maplibre-gl-shared.mjs"]) {
  await copyFile(new URL(`../node_modules/maplibre-gl/dist/${file}`, import.meta.url), new URL(file, output));
}
await copyFile(new URL("../node_modules/maplibre-gl/LICENSE.txt", import.meta.url), new URL("LICENSE.txt", output));
