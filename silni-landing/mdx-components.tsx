import type { MDXComponents } from "mdx/types";

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    h1: ({ children }) => (
      <h1 className="text-headline-lg text-primary-deep mb-lg">{children}</h1>
    ),
    h2: ({ children }) => (
      <h2 className="text-headline-md text-primary-deep mt-2xl mb-md">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="text-headline-sm text-primary-deep mt-xl mb-sm">{children}</h3>
    ),
    p: ({ children }) => (
      <p className="text-body-lg text-text-secondary leading-relaxed mb-md">{children}</p>
    ),
    blockquote: ({ children }) => (
      <blockquote className="border-r-4 border-primary pr-lg my-lg text-primary-deep font-amiri text-xl leading-loose">
        {children}
      </blockquote>
    ),
    ul: ({ children }) => (
      <ul className="list-disc list-inside space-y-sm mb-md text-body-lg text-text-secondary">{children}</ul>
    ),
    ...components,
  };
}
