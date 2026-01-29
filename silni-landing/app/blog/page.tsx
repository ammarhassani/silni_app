import type { Metadata } from "next";
import { getAllPosts } from "@/lib/blog";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import ScrollReveal from "@/components/animations/ScrollReveal";
import BlogCard from "@/components/ui/BlogCard";

export const metadata: Metadata = {
  title: "مدونة صِلني — مقالات عن صلة الرحم والعائلة",
  description: "مقالات ونصائح عن صلة الرحم، العلاقات العائلية، والتواصل الفعّال.",
};

export default function BlogPage() {
  const posts = getAllPosts();

  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="المدونة" as="h1" className="text-hero mb-md" />
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          {posts.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-lg">
              {posts.map((post) => (
                <ScrollReveal key={post.slug}>
                  <BlogCard post={post} />
                </ScrollReveal>
              ))}
            </div>
          ) : (
            <p className="text-center text-text-secondary text-body-lg">
              قريباً — مقالات جديدة عن صلة الرحم
            </p>
          )}
        </div>
      </section>
    </>
  );
}
