import type { Metadata } from "next";
import JoinClient from "./JoinClient";

export const metadata: Metadata = {
  title: "انضم للعائلة",
  description: "تم دعوتك للانضمام لشجرة عائلة في صِلني",
};

export function generateStaticParams() {
  // Only generate the base /join page — invite codes are handled client-side.
  // The hosting platform should rewrite /join/* to /join/index.html.
  return [{ code: [] }];
}

export default function JoinPage() {
  return <JoinClient />;
}
