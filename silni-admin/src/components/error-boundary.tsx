"use client";

import { Component, ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertTriangle, RefreshCw, Home } from "lucide-react";
import Link from "next/link";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: React.ErrorInfo | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: null };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    this.setState({ errorInfo });
    // Log to error reporting service
    console.error("Error Boundary caught an error:", error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="min-h-[400px] flex items-center justify-center p-6">
          <Card className="max-w-lg w-full">
            <CardHeader className="text-center">
              <div className="w-16 h-16 mx-auto bg-destructive/10 rounded-full flex items-center justify-center mb-4">
                <AlertTriangle className="h-8 w-8 text-destructive" />
              </div>
              <CardTitle className="text-xl">حدث خطأ غير متوقع</CardTitle>
              <CardDescription>
                نأسف، حدث خطأ أثناء تحميل هذا المحتوى. يرجى المحاولة مرة أخرى.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {process.env.NODE_ENV === "development" && this.state.error && (
                <div className="p-4 bg-muted rounded-lg overflow-auto max-h-[200px]">
                  <p className="text-sm font-mono text-destructive">
                    {this.state.error.message}
                  </p>
                  {this.state.errorInfo && (
                    <pre className="text-xs mt-2 text-muted-foreground whitespace-pre-wrap">
                      {this.state.errorInfo.componentStack}
                    </pre>
                  )}
                </div>
              )}
              <div className="flex gap-3 justify-center">
                <Button onClick={this.handleReset} variant="outline">
                  <RefreshCw className="h-4 w-4 ml-2" />
                  إعادة المحاولة
                </Button>
                <Link href="/dashboard">
                  <Button>
                    <Home className="h-4 w-4 ml-2" />
                    العودة للرئيسية
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>
      );
    }

    return this.props.children;
  }
}

// Query Error Fallback component for React Query
interface QueryErrorProps {
  error: Error;
  resetErrorBoundary: () => void;
}

export function QueryErrorFallback({ error, resetErrorBoundary }: QueryErrorProps) {
  return (
    <div className="min-h-[200px] flex items-center justify-center p-6">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center pb-2">
          <div className="w-12 h-12 mx-auto bg-destructive/10 rounded-full flex items-center justify-center mb-3">
            <AlertTriangle className="h-6 w-6 text-destructive" />
          </div>
          <CardTitle className="text-lg">فشل تحميل البيانات</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-center text-muted-foreground">
            {error.message || "حدث خطأ أثناء جلب البيانات"}
          </p>
          <div className="flex justify-center">
            <Button onClick={resetErrorBoundary} size="sm">
              <RefreshCw className="h-4 w-4 ml-2" />
              إعادة المحاولة
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Inline error component for smaller errors
interface InlineErrorProps {
  message?: string;
  onRetry?: () => void;
}

export function InlineError({ message = "حدث خطأ", onRetry }: InlineErrorProps) {
  return (
    <div className="flex items-center gap-3 p-4 bg-destructive/10 rounded-lg text-destructive">
      <AlertTriangle className="h-5 w-5 flex-shrink-0" />
      <p className="text-sm flex-1">{message}</p>
      {onRetry && (
        <Button
          variant="ghost"
          size="sm"
          onClick={onRetry}
          className="text-destructive hover:text-destructive"
        >
          <RefreshCw className="h-4 w-4" />
        </Button>
      )}
    </div>
  );
}

// Empty state component
interface EmptyStateProps {
  icon?: React.ElementType;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="text-center py-12">
      {Icon && (
        <div className="w-16 h-16 mx-auto bg-muted rounded-full flex items-center justify-center mb-4">
          <Icon className="h-8 w-8 text-muted-foreground" />
        </div>
      )}
      <h3 className="text-lg font-medium">{title}</h3>
      {description && (
        <p className="text-muted-foreground mt-1">{description}</p>
      )}
      {action && (
        <Button variant="outline" className="mt-4" onClick={action.onClick}>
          {action.label}
        </Button>
      )}
    </div>
  );
}

// Loading skeleton variations
export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="space-y-4">
      <div className="flex gap-4 pb-4 border-b">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="h-4 bg-muted rounded animate-pulse flex-1" />
        ))}
      </div>
      {[...Array(rows)].map((_, i) => (
        <div key={i} className="flex gap-4 py-3">
          {[...Array(4)].map((_, j) => (
            <div key={j} className="h-4 bg-muted rounded animate-pulse flex-1" />
          ))}
        </div>
      ))}
    </div>
  );
}

export function CardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <div className="h-6 w-32 bg-muted rounded animate-pulse" />
        <div className="h-4 w-48 bg-muted rounded animate-pulse mt-2" />
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          <div className="h-4 bg-muted rounded animate-pulse" />
          <div className="h-4 bg-muted rounded animate-pulse w-3/4" />
        </div>
      </CardContent>
    </Card>
  );
}

export function FormSkeleton() {
  return (
    <div className="space-y-6">
      {[...Array(4)].map((_, i) => (
        <div key={i} className="space-y-2">
          <div className="h-4 w-24 bg-muted rounded animate-pulse" />
          <div className="h-10 bg-muted rounded animate-pulse" />
        </div>
      ))}
      <div className="flex gap-3 justify-end">
        <div className="h-10 w-24 bg-muted rounded animate-pulse" />
        <div className="h-10 w-32 bg-muted rounded animate-pulse" />
      </div>
    </div>
  );
}
