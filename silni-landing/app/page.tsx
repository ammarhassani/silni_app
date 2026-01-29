import Hero from "@/components/sections/Hero";
import ProblemCards from "@/components/sections/ProblemCards";
import StickyFeatures from "@/components/sections/StickyFeatures";
import SocialProof from "@/components/sections/SocialProof";
import NewsletterSignup from "@/components/sections/NewsletterSignup";

export default function Home() {
  return (
    <>
      <Hero />
      <ProblemCards />
      <StickyFeatures />
      <SocialProof />
      <NewsletterSignup />
    </>
  );
}
