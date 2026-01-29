"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import type { BlogPost } from "@/lib/blog";

export default function BlogCard({ post }: { post: BlogPost }) {
  return (
    <Link href={`/blog/${post.slug}`}>
      <motion.article
        className="bg-white rounded-card overflow-hidden shadow-sm group"
        whileHover={{ y: -8, boxShadow: "0 20px 40px rgba(0,0,0,0.1)" }}
        transition={{ duration: 0.3 }}
      >
        <div className="h-3 gradient-primary" />

        <div className="p-xl">
          <div className="flex items-center gap-md text-body-md text-text-hint mb-md">
            <span>{new Date(post.date).toLocaleDateString("ar-SA")}</span>
            <span>·</span>
            <span>{post.readingTime}</span>
          </div>

          <h3 className="text-headline-sm text-primary-deep mb-sm group-hover:text-primary transition-colors">
            {post.title}
          </h3>

          <p className="text-body-lg text-text-secondary leading-relaxed line-clamp-2">
            {post.description}
          </p>

          <span className="inline-block mt-md text-primary text-label-lg group-hover:underline">
            اقرأ المزيد ←
          </span>
        </div>
      </motion.article>
    </Link>
  );
}
