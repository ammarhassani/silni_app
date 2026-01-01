# Silni Admin Panel - Comprehensive Test Suggestions

This document outlines enterprise-grade testing strategies for the Silni Admin Panel.

## Testing Stack Recommendations

```bash
# Install testing dependencies
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event
npm install -D @vitejs/plugin-react jsdom
npm install -D msw  # For API mocking
npm install -D @faker-js/faker  # For test data generation
npm install -D playwright  # For E2E testing
```

---

## 1. Unit Tests

### 1.1 Hook Tests

#### `use-content.ts` Tests
```typescript
// __tests__/hooks/use-content.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useHadithList, useQuotesList, useMOTDList, useBannersList } from '@/hooks/use-content';

describe('useHadithList', () => {
  it('should fetch hadith list with pagination', async () => {
    const { result } = renderHook(() => useHadithList(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data?.pages[0].items).toBeDefined();
  });

  it('should filter by category', async () => {
    const { result } = renderHook(() => useHadithList({ category: 'general' }), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    result.current.data?.pages[0].items.forEach(item => {
      expect(item.category).toBe('general');
    });
  });

  it('should filter by grade', async () => {
    const { result } = renderHook(() => useHadithList({ grade: 'صحيح' }), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
  });

  it('should search hadith text', async () => {
    const { result } = renderHook(() => useHadithList({ search: 'النبي' }), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
  });

  it('should handle infinite scroll pagination', async () => {
    const { result } = renderHook(() => useHadithList(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    if (result.current.hasNextPage) {
      result.current.fetchNextPage();
      await waitFor(() => expect(result.current.data?.pages.length).toBeGreaterThan(1));
    }
  });
});

describe('useCreateHadith', () => {
  it('should create a new hadith', async () => {
    // Test mutation
  });

  it('should invalidate queries on success', async () => {
    // Test cache invalidation
  });

  it('should show success toast', async () => {
    // Test toast notification
  });
});

describe('useDeleteHadith', () => {
  it('should delete hadith by id', async () => {
    // Test deletion
  });

  it('should handle errors gracefully', async () => {
    // Test error handling
  });
});
```

#### `use-gamification.ts` Tests
```typescript
// __tests__/hooks/use-gamification.test.ts
describe('useBadgesList', () => {
  it('should fetch all badges', async () => {});
  it('should filter by category', async () => {});
  it('should sort by sort_order', async () => {});
});

describe('useLevelsList', () => {
  it('should fetch levels in order', async () => {});
  it('should validate XP progression', async () => {});
});

describe('useChallengesList', () => {
  it('should fetch active challenges', async () => {});
  it('should filter by type', async () => {});
});

describe('useStreakConfig', () => {
  it('should fetch active streak config', async () => {});
  it('should handle no config gracefully', async () => {});
});
```

#### `use-dashboard.ts` Tests
```typescript
// __tests__/hooks/use-dashboard.test.ts
describe('useDashboardStats', () => {
  it('should aggregate stats from all modules', async () => {});
  it('should handle partial failures', async () => {});
  it('should cache for 1 minute', async () => {});
});

describe('useSystemHealth', () => {
  it('should check database connection', async () => {});
  it('should check AI configuration', async () => {});
  it('should check storage', async () => {});
  it('should refetch periodically', async () => {});
});

describe('useRecentActivity', () => {
  it('should fetch recent updates', async () => {});
  it('should sort by timestamp', async () => {});
  it('should limit to 10 items', async () => {});
});
```

### 1.2 Utility Tests

```typescript
// __tests__/lib/utils.test.ts
import { cn, truncate } from '@/lib/utils';

describe('cn', () => {
  it('should merge class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar');
  });

  it('should handle conditional classes', () => {
    expect(cn('foo', false && 'bar', 'baz')).toBe('foo baz');
  });

  it('should handle tailwind conflicts', () => {
    expect(cn('text-red-500', 'text-blue-500')).toBe('text-blue-500');
  });
});

describe('truncate', () => {
  it('should truncate long strings', () => {
    expect(truncate('hello world', 5)).toBe('hello...');
  });

  it('should not truncate short strings', () => {
    expect(truncate('hi', 5)).toBe('hi');
  });
});
```

---

## 2. Component Tests

### 2.1 Dialog Component Tests

```typescript
// __tests__/components/quote-dialog.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QuoteDialog } from '@/app/(dashboard)/content/quotes/quote-dialog';

describe('QuoteDialog', () => {
  it('should render create mode when quote is null', () => {
    render(<QuoteDialog open={true} onOpenChange={() => {}} quote={null} />);
    expect(screen.getByText('إضافة اقتباس جديد')).toBeInTheDocument();
  });

  it('should render edit mode when quote is provided', () => {
    const quote = { id: '1', quote_text: 'Test quote', ...otherFields };
    render(<QuoteDialog open={true} onOpenChange={() => {}} quote={quote} />);
    expect(screen.getByText('تعديل الاقتباس')).toBeInTheDocument();
  });

  it('should populate form with existing data', () => {
    const quote = { id: '1', quote_text: 'Test quote', author: 'Author' };
    render(<QuoteDialog open={true} onOpenChange={() => {}} quote={quote} />);
    expect(screen.getByDisplayValue('Test quote')).toBeInTheDocument();
  });

  it('should validate required fields', async () => {
    render(<QuoteDialog open={true} onOpenChange={() => {}} quote={null} />);
    fireEvent.click(screen.getByText('إضافة الاقتباس'));
    await waitFor(() => {
      expect(screen.getByText(/نص الاقتباس مطلوب/)).toBeInTheDocument();
    });
  });

  it('should call create mutation on submit', async () => {
    const user = userEvent.setup();
    render(<QuoteDialog open={true} onOpenChange={() => {}} quote={null} />);

    await user.type(screen.getByLabelText('نص الاقتباس'), 'New quote text');
    await user.click(screen.getByText('إضافة الاقتباس'));

    // Assert mutation was called
  });

  it('should close dialog on cancel', async () => {
    const onOpenChange = vi.fn();
    render(<QuoteDialog open={true} onOpenChange={onOpenChange} quote={null} />);
    fireEvent.click(screen.getByText('إلغاء'));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });
});
```

### 2.2 Page Component Tests

```typescript
// __tests__/pages/quotes-page.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import QuotesPage from '@/app/(dashboard)/content/quotes/page';

describe('QuotesPage', () => {
  it('should render page title', () => {
    render(<QuotesPage />);
    expect(screen.getByText('الاقتباسات')).toBeInTheDocument();
  });

  it('should show loading skeletons initially', () => {
    render(<QuotesPage />);
    expect(screen.getAllByRole('progressbar')).toHaveLength(5);
  });

  it('should display quotes in table', async () => {
    render(<QuotesPage />);
    await waitFor(() => {
      expect(screen.getByRole('table')).toBeInTheDocument();
    });
  });

  it('should filter by category', async () => {
    render(<QuotesPage />);
    // Select category filter
    // Assert filtered results
  });

  it('should search quotes', async () => {
    render(<QuotesPage />);
    // Type in search input
    // Assert debounced search
  });

  it('should open create dialog', async () => {
    render(<QuotesPage />);
    fireEvent.click(screen.getByText('إضافة اقتباس'));
    expect(screen.getByText('إضافة اقتباس جديد')).toBeInTheDocument();
  });

  it('should load more on scroll', async () => {
    render(<QuotesPage />);
    // Simulate infinite scroll
    // Assert fetchNextPage called
  });
});
```

### 2.3 Error Boundary Tests

```typescript
// __tests__/components/error-boundary.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { ErrorBoundary, QueryErrorFallback, InlineError } from '@/components/error-boundary';

describe('ErrorBoundary', () => {
  it('should render children when no error', () => {
    render(
      <ErrorBoundary>
        <div>Content</div>
      </ErrorBoundary>
    );
    expect(screen.getByText('Content')).toBeInTheDocument();
  });

  it('should render error UI when error occurs', () => {
    const ThrowError = () => { throw new Error('Test error'); };
    render(
      <ErrorBoundary>
        <ThrowError />
      </ErrorBoundary>
    );
    expect(screen.getByText('حدث خطأ غير متوقع')).toBeInTheDocument();
  });

  it('should reset on retry click', () => {
    // Test reset functionality
  });
});

describe('QueryErrorFallback', () => {
  it('should display error message', () => {
    const error = new Error('Failed to fetch');
    render(<QueryErrorFallback error={error} resetErrorBoundary={() => {}} />);
    expect(screen.getByText('Failed to fetch')).toBeInTheDocument();
  });

  it('should call resetErrorBoundary on retry', () => {
    const resetFn = vi.fn();
    render(<QueryErrorFallback error={new Error('Error')} resetErrorBoundary={resetFn} />);
    fireEvent.click(screen.getByText('إعادة المحاولة'));
    expect(resetFn).toHaveBeenCalled();
  });
});

describe('InlineError', () => {
  it('should display custom message', () => {
    render(<InlineError message="Custom error" />);
    expect(screen.getByText('Custom error')).toBeInTheDocument();
  });

  it('should show retry button when onRetry provided', () => {
    render(<InlineError onRetry={() => {}} />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });
});
```

---

## 3. Integration Tests

### 3.1 CRUD Flow Tests

```typescript
// __tests__/integration/content-crud.test.tsx
describe('Content CRUD Operations', () => {
  describe('Hadith', () => {
    it('should create, read, update, delete hadith', async () => {
      // 1. Create new hadith
      // 2. Verify it appears in list
      // 3. Edit the hadith
      // 4. Verify changes persisted
      // 5. Delete the hadith
      // 6. Verify it's removed from list
    });
  });

  describe('Quotes', () => {
    it('should handle bulk operations', async () => {
      // Test bulk delete functionality
    });
  });

  describe('MOTD', () => {
    it('should validate date ranges', async () => {
      // Test start_date < end_date validation
    });
  });

  describe('Banners', () => {
    it('should track impressions and clicks', async () => {
      // Verify analytics tracking
    });
  });
});
```

### 3.2 Authentication Flow Tests

```typescript
// __tests__/integration/auth.test.tsx
describe('Authentication', () => {
  it('should redirect unauthenticated users to login', async () => {});
  it('should persist session across page reloads', async () => {});
  it('should handle session expiry gracefully', async () => {});
  it('should logout and clear session', async () => {});
});
```

---

## 4. E2E Tests (Playwright)

```typescript
// e2e/content-management.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Content Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login and navigate to content
    await page.goto('/login');
    await page.fill('[name="email"]', 'admin@silni.app');
    await page.fill('[name="password"]', 'password');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
  });

  test('should create a new hadith', async ({ page }) => {
    await page.goto('/content/hadith');
    await page.click('text=إضافة حديث');

    await page.fill('[name="hadith_text"]', 'حديث تجريبي للاختبار');
    await page.fill('[name="source"]', 'صحيح البخاري');
    await page.selectOption('[name="grade"]', 'صحيح');

    await page.click('text=إضافة الحديث');

    await expect(page.locator('text=تم إضافة الحديث بنجاح')).toBeVisible();
  });

  test('should search and filter content', async ({ page }) => {
    await page.goto('/content/quotes');

    // Search
    await page.fill('[placeholder="بحث في الاقتباسات..."]', 'حكمة');
    await page.waitForTimeout(500); // Debounce

    // Filter by category
    await page.click('[data-testid="category-filter"]');
    await page.click('text=حكمة');

    // Verify filtered results
    await expect(page.locator('table tbody tr')).toHaveCount(expectedCount);
  });

  test('should handle pagination', async ({ page }) => {
    await page.goto('/content/hadith');

    // Scroll to load more
    await page.click('text=تحميل المزيد');

    // Verify more items loaded
  });
});

test.describe('Dashboard', () => {
  test('should display real-time stats', async ({ page }) => {
    await page.goto('/dashboard');

    // Verify stats are loaded
    await expect(page.locator('[data-testid="content-stats"]')).not.toContainText('0');
  });

  test('should show system health status', async ({ page }) => {
    await page.goto('/dashboard');

    await expect(page.locator('text=قاعدة البيانات')).toBeVisible();
    await expect(page.locator('text=متصل')).toBeVisible();
  });
});
```

---

## 5. API Mocking with MSW

```typescript
// __tests__/mocks/handlers.ts
import { rest } from 'msw';
import { faker } from '@faker-js/faker/locale/ar';

const generateHadith = () => ({
  id: faker.string.uuid(),
  hadith_text: faker.lorem.paragraph(),
  source: faker.helpers.arrayElement(['صحيح البخاري', 'صحيح مسلم', 'سنن أبي داود']),
  narrator: faker.person.fullName(),
  grade: faker.helpers.arrayElement(['صحيح', 'حسن', 'ضعيف']),
  category: 'general',
  is_active: true,
  display_priority: faker.number.int({ min: 0, max: 10 }),
  created_at: faker.date.past().toISOString(),
  updated_at: faker.date.recent().toISOString(),
});

export const handlers = [
  // Hadith endpoints
  rest.get('*/admin_hadith*', (req, res, ctx) => {
    const items = Array.from({ length: 20 }, generateHadith);
    return res(ctx.json(items), ctx.set('Content-Range', '0-19/100'));
  }),

  rest.post('*/admin_hadith', (req, res, ctx) => {
    return res(ctx.json({ ...req.body, id: faker.string.uuid() }));
  }),

  rest.patch('*/admin_hadith*', (req, res, ctx) => {
    return res(ctx.json(req.body));
  }),

  rest.delete('*/admin_hadith*', (req, res, ctx) => {
    return res(ctx.status(204));
  }),

  // Add more handlers for other endpoints...
];
```

---

## 6. Performance Tests

```typescript
// __tests__/performance/load-times.test.ts
describe('Performance', () => {
  it('should load dashboard within 2s', async () => {
    const start = performance.now();
    await page.goto('/dashboard');
    await page.waitForSelector('[data-testid="dashboard-loaded"]');
    const loadTime = performance.now() - start;
    expect(loadTime).toBeLessThan(2000);
  });

  it('should handle large datasets efficiently', async () => {
    // Test with 1000+ items
    // Verify virtual scrolling works
    // Check memory usage
  });

  it('should not re-render unnecessarily', async () => {
    // Use React DevTools profiler
    // Count renders
  });
});
```

---

## 7. Accessibility Tests

```typescript
// __tests__/a11y/accessibility.test.tsx
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('Accessibility', () => {
  it('should have no accessibility violations on dashboard', async () => {
    const { container } = render(<DashboardPage />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should have no violations on dialogs', async () => {
    const { container } = render(
      <QuoteDialog open={true} onOpenChange={() => {}} quote={null} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should support keyboard navigation', async () => {
    render(<QuotesPage />);
    // Tab through elements
    // Verify focus order
    // Test enter/space activation
  });

  it('should have proper ARIA labels', async () => {
    render(<QuotesPage />);
    expect(screen.getByRole('searchbox')).toHaveAttribute('aria-label');
    expect(screen.getByRole('table')).toHaveAttribute('aria-label');
  });
});
```

---

## 8. Test Configuration

### vitest.config.ts
```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/__tests__/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', '__tests__/'],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### vitest.setup.ts
```typescript
import '@testing-library/jest-dom';
import { server } from './__tests__/mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  usePathname: () => '/dashboard',
  useSearchParams: () => new URLSearchParams(),
}));
```

---

## 9. CI/CD Test Configuration

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run test:unit
      - run: npm run test:integration

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  e2e:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4

      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e

      - uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

---

## 10. Test Coverage Goals

| Module | Target Coverage |
|--------|-----------------|
| Hooks | 90%+ |
| Components | 85%+ |
| Pages | 80%+ |
| Utils | 95%+ |
| Overall | 85%+ |

---

## Quick Start Commands

```bash
# Run all unit tests
npm run test

# Run with coverage
npm run test:coverage

# Run specific test file
npm run test -- use-content.test.ts

# Run E2E tests
npm run test:e2e

# Run E2E in UI mode
npm run test:e2e:ui

# Run accessibility tests
npm run test:a11y
```

---

## Summary

This testing strategy covers:
- **Unit Tests**: Individual hooks, utilities, and components
- **Integration Tests**: CRUD flows and module interactions
- **E2E Tests**: Full user journeys with Playwright
- **Performance Tests**: Load times and efficiency
- **Accessibility Tests**: WCAG compliance

Following these test patterns will ensure the admin panel is robust, maintainable, and enterprise-ready.
