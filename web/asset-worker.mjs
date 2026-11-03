// Only /index.wasm runs through this Pages Worker (see generated _routes.json).
// The stored .gz file has no Content-Encoding header. Mark its bytes as already
// encoded here, preventing the Workers runtime from gzip-encoding them again.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/index.wasm") return env.ASSETS.fetch(request);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { Allow: "GET, HEAD", "Cache-Control": "no-store" },
      });
    }

    url.pathname = "/index.wasm.gz";
    // Do not forward conditional or range requests: this endpoint deliberately
    // serves one complete encoded module, or its headers for HEAD.
    const upstream = await env.ASSETS.fetch(new Request(url, {
      method: request.method,
      headers: { "Accept-Encoding": "identity" },
    }));
    const type = (upstream.headers.get("Content-Type") || "").split(";")[0].trim();
    // Missing Pages assets can fall back to index.html with status 200. Do not
    // disguise an HTML error page (or an already encoded response) as WebAssembly.
    if (upstream.status !== 200 || upstream.headers.has("Content-Encoding") ||
        !["application/gzip", "application/x-gzip", "application/octet-stream"].includes(type)) {
      await upstream.body?.cancel();
      return new Response(request.method === "HEAD" ? null : "Engine asset not found", {
        status: 404,
        headers: { "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" },
      });
    }

    const headers = new Headers(upstream.headers);
    headers.set("Content-Type", "application/wasm");
    headers.set("Content-Encoding", "gzip");
    headers.set("Cache-Control", "no-cache, no-transform");
    headers.set("Vary", "Accept-Encoding");
    headers.set("X-Content-Type-Options", "nosniff");
    headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
    headers.delete("Content-Disposition");
    headers.delete("Accept-Ranges");
    headers.delete("Content-Range");
    return new Response(request.method === "HEAD" ? null : upstream.body, {
      status: 200,
      headers,
      encodeBody: "manual",
    });
  },
};
