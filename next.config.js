import type { NextConfig } from "next";

// Read per-preview asset prefix injected by the orchestrator
const assetPrefix = process.env.ASSET_PREFIX ?? "";

const nextConfig: NextConfig = {
  /**
   * Make Next emit JS/CSS/HMR and image optimizer under /p/<id>/_next/...
   * Your orchestrator should set ASSET_PREFIX=/p/<id> when starting `next dev`.
   */
  assetPrefix,

  /**
   * Ensure next/image optimizer also respects the prefix
   * (safe even if you don’t use next/image).
   */
  images: {
    path: `${assetPrefix}/_next/image`,
  },

  /**
   * Security headers
   * Allow embedding pages inside frames from your domain and localhost (any port).
   */
  async headers() {
    // Allow same-origin, your production domain, and localhost (HTTP/HTTPS, any port)
    const frameAncestors =
      "frame-ancestors 'self' https://minidev.fun https://*.minidev.fun https://farcaster.xyz https://*.farcaster.xyz http://localhost:* http://127.0.0.1:* https://127.0.0.1:*";

    return [
      {
        source: "/:path*",
        headers: [
          {
            key: "Content-Security-Policy",
            value: frameAncestors,
          },
        ],
      },
    ];
  },
};

export default nextConfig;
