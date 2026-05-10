import createMDX from "@next/mdx";

/** @type {import('next').NextConfig} */
const nextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
  // No `output: "export"` — Vercel runs Next.js natively, which is required
  // for the dynamic catch-all route /join/[[...code]] to handle arbitrary
  // codes. Static export emits placeholder filenames for catch-all routes
  // and 404s on real codes.
  images: {
    unoptimized: true,
  },
};

const withMDX = createMDX({});

export default withMDX(nextConfig);
