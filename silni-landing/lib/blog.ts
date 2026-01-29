import fs from "fs";
import path from "path";
import matter from "gray-matter";
import readingTime from "reading-time";

const BLOG_DIR = path.join(process.cwd(), "content/blog");

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  date: string;
  readingTime: string;
  image?: string;
}

export function getAllPosts(): BlogPost[] {
  if (!fs.existsSync(BLOG_DIR)) return [];

  const files = fs.readdirSync(BLOG_DIR).filter((f) => f.endsWith(".mdx"));

  const posts = files.map((file) => {
    const slug = file.replace(/\.mdx$/, "");
    const source = fs.readFileSync(path.join(BLOG_DIR, file), "utf8");
    const { data, content } = matter(source);
    const rt = readingTime(content);

    return {
      slug,
      title: data.title || "",
      description: data.description || "",
      date: data.date || "",
      readingTime: rt.text.replace("min read", "دقائق للقراءة"),
      image: data.image,
    };
  });

  return posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

export function getPostBySlug(slug: string) {
  const filePath = path.join(BLOG_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return null;

  const source = fs.readFileSync(filePath, "utf8");
  const { data, content } = matter(source);
  const rt = readingTime(content);

  return {
    slug,
    title: data.title || "",
    description: data.description || "",
    date: data.date || "",
    readingTime: rt.text.replace("min read", "دقائق للقراءة"),
    image: data.image,
    content,
  };
}
