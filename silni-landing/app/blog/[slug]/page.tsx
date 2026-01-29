import { notFound } from "next/navigation";
import { getAllPosts, getPostBySlug } from "@/lib/blog";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

export async function generateStaticParams() {
  const posts = getAllPosts();
  return posts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) return {};
  return {
    title: `${post.title} — مدونة صِلني`,
    description: post.description,
  };
}

export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) notFound();

  // Simple markdown-to-html conversion for the content
  const htmlContent = post.content
    .split("\n\n")
    .map((block) => {
      if (block.startsWith("## ")) {
        return `<h2 class="text-headline-md text-primary-deep mt-2xl mb-md">${block.slice(3)}</h2>`;
      }
      if (block.startsWith("> ")) {
        const text = block.replace(/^> /gm, "");
        return `<blockquote class="border-r-4 border-primary pr-lg my-lg text-primary-deep font-amiri text-xl leading-loose"><p>${text}</p></blockquote>`;
      }
      if (block.startsWith("- ")) {
        const items = block.split("\n").map((line) => `<li>${line.slice(2)}</li>`).join("");
        return `<ul class="list-disc list-inside space-y-sm mb-md text-body-lg text-text-secondary">${items}</ul>`;
      }
      return `<p class="text-body-lg text-text-secondary leading-relaxed mb-md">${block}</p>`;
    })
    .join("");

  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text={post.title} as="h1" className="text-dramatic mb-md" />
          <ScrollReveal delay={0.4}>
            <div className="flex items-center justify-center gap-md text-white/60 text-body-lg">
              <span>{new Date(post.date).toLocaleDateString("ar-SA")}</span>
              <span>·</span>
              <span>{post.readingTime}</span>
            </div>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <ScrollReveal>
          <article
            className="max-w-3xl mx-auto px-md lg:px-xl"
            dangerouslySetInnerHTML={{ __html: htmlContent }}
          />
        </ScrollReveal>
      </section>
    </>
  );
}
