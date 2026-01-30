import Hero from "@/components/sections/Hero";
import ProblemCards from "@/components/sections/ProblemCards";
import StickyFeatures from "@/components/sections/StickyFeatures";
import NewsletterSignup from "@/components/sections/NewsletterSignup";

export default function Home() {
  return (
    <>
      <Hero />
      <ProblemCards />
      <StickyFeatures />
      <NewsletterSignup />
    </>
  );
}
