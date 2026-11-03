import assert from "node:assert/strict";
import { gzipSync, gunzipSync } from "node:zlib";
import { test } from "node:test";
import worker from "../web/asset-worker.mjs";

const wasm = Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]);
const compressed = gzipSync(wasm);

function assets(response) {
  const requests = [];
  return {
    requests,
    ASSETS: { fetch: async (request) => { requests.push(request); return response(); } },
  };
}

test("serves the original gzip bytes once with manual encoding", async (t) => {
  const NativeResponse = Response;
  const inits = [];
  t.mock.method(globalThis, "Response", function (body, init) {
    inits.push(init);
    return new NativeResponse(body, init);
  });
  const env = assets(() => new NativeResponse(compressed, {
    headers: { "Content-Type": "application/gzip", "Content-Length": String(compressed.length), ETag: '"engine"' },
  }));
  const response = await worker.fetch(new Request("https://game.example/index.wasm?version=1", {
    headers: { Range: "bytes=0-4", "If-None-Match": '"old"', "If-Modified-Since": "yesterday", "Accept-Encoding": "gzip, br" },
  }), env);
  assert.equal(env.requests[0].url, "https://game.example/index.wasm.gz?version=1");
  assert.deepEqual([...env.requests[0].headers], [["accept-encoding", "identity"]]);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Content-Type"), "application/wasm");
  assert.equal(response.headers.get("Content-Encoding"), "gzip");
  assert.equal(response.headers.get("Vary"), "Accept-Encoding");
  assert.equal(response.headers.get("Cache-Control"), "no-cache, no-transform");
  assert.equal(response.headers.get("ETag"), '"engine"');
  assert.equal(inits.at(-1).encodeBody, "manual");
  const bytes = Buffer.from(await response.arrayBuffer());
  assert.deepEqual(bytes, compressed);
  assert.deepEqual(gunzipSync(bytes), wasm);
});

test("HEAD returns the same encoded length and no body", async () => {
  const env = assets(() => new Response(null, {
    headers: { "Content-Type": "application/gzip", "Content-Length": String(compressed.length) },
  }));
  const response = await worker.fetch(new Request("https://game.example/index.wasm", { method: "HEAD" }), env);
  assert.equal(env.requests[0].method, "HEAD");
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Content-Length"), String(compressed.length));
  assert.equal((await response.arrayBuffer()).byteLength, 0);
});

test("unsupported methods cannot reach assets", async () => {
  const env = assets(() => { throw new Error("Unexpected asset read"); });
  const response = await worker.fetch(new Request("https://game.example/index.wasm", { method: "POST" }), env);
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("Allow"), "GET, HEAD");
  assert.equal(env.requests.length, 0);
});

test("other paths pass directly to static assets", async () => {
  const request = new Request("https://game.example/index.js");
  const env = assets(() => new Response("loader"));
  const response = await worker.fetch(request, env);
  assert.equal(env.requests[0], request);
  assert.equal(await response.text(), "loader");
});

test("missing, HTML fallback and unexpectedly encoded assets return 404", async () => {
  for (const [status, type, encoding] of [
    [404, "text/plain", null], [200, "text/html", null], [200, "application/gzip", "gzip"], [206, "application/gzip", null],
  ]) {
    const env = assets(() => new Response("wrong response", {
      status,
      headers: { "Content-Type": type, ...(encoding ? { "Content-Encoding": encoding } : {}) },
    }));
    const response = await worker.fetch(new Request("https://game.example/index.wasm"), env);
    assert.equal(response.status, 404);
    assert.equal(response.headers.get("Cache-Control"), "no-store");
    assert.equal(response.headers.get("Content-Encoding"), null);
  }
});
