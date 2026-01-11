'use client';

import { config, CURRENT_ENV, isProduction } from '@/lib/env-config';
import { Database, Server, AlertTriangle } from 'lucide-react';

interface EnvironmentIndicatorProps {
  /** Compact mode for header */
  compact?: boolean;
}

/**
 * Read-only environment indicator.
 * Shows which environment this deployment is connected to.
 * No runtime switching - environment is determined at build time.
 */
export function EnvironmentIndicator({ compact = false }: EnvironmentIndicatorProps) {
  const isProd = isProduction();

  if (compact) {
    return (
      <div
        className={`
          flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium
          border cursor-default
          ${isProd
            ? 'bg-green-500/20 text-green-400 border-green-500/50'
            : 'bg-amber-500/20 text-amber-400 border-amber-500/50'
          }
        `}
        title={`Connected to ${config.label} environment`}
      >
        {isProd ? (
          <Server className="h-3.5 w-3.5" />
        ) : (
          <Database className="h-3.5 w-3.5" />
        )}
        <span>{config.label}</span>
      </div>
    );
  }

  return (
    <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-medium text-gray-300">Environment</h3>
        {isProd && (
          <div className="flex items-center gap-1 text-amber-400 text-xs">
            <AlertTriangle className="h-3.5 w-3.5" />
            <span>Production Mode</span>
          </div>
        )}
      </div>

      <div
        className={`
          flex items-center justify-center gap-2 px-4 py-2 rounded-lg
          text-sm font-medium border
          ${isProd
            ? 'bg-green-500/20 text-green-400 border-green-500'
            : 'bg-amber-500/20 text-amber-400 border-amber-500'
          }
        `}
      >
        {isProd ? (
          <Server className="h-4 w-4" />
        ) : (
          <Database className="h-4 w-4" />
        )}
        <span>{config.label}</span>
      </div>

      <div className="mt-3 text-xs text-gray-500">
        <p>URL: <span className="text-gray-400 font-mono text-[10px]">{config.supabaseUrl}</span></p>
      </div>
    </div>
  );
}

/**
 * Environment badge for header/navigation
 */
export function EnvironmentBadge() {
  const isProd = isProduction();

  return (
    <div
      className={`
        inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-medium
        ${isProd
          ? 'bg-green-500/20 text-green-400'
          : 'bg-amber-500/20 text-amber-400'
        }
      `}
    >
      <span
        className={`
          w-1.5 h-1.5 rounded-full
          ${isProd ? 'bg-green-400' : 'bg-amber-400'}
          ${isProd ? 'animate-pulse' : ''}
        `}
      />
      {config.label}
    </div>
  );
}
