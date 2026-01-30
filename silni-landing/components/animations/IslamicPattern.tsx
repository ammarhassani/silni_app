interface IslamicPatternProps {
  className?: string;
  color?: string;
  opacity?: number;
}

export default function IslamicPattern({
  className = "",
  color = "#81C784",
  opacity = 0.08,
}: IslamicPatternProps) {
  return (
    <div className={`absolute inset-0 overflow-hidden pointer-events-none ${className}`}>
      <svg
        className="w-full h-full"
        viewBox="0 0 800 800"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid slice"
      >
        {Array.from({ length: 6 }).map((_, row) =>
          Array.from({ length: 6 }).map((_, col) => {
            const cx = col * 160 + 80;
            const cy = row * 160 + 80;
            return (
              <g key={`${row}-${col}`}>
                <path
                  d={`M ${cx} ${cy - 40} L ${cx + 12} ${cy - 12} L ${cx + 40} ${cy} L ${cx + 12} ${cy + 12} L ${cx} ${cy + 40} L ${cx - 12} ${cy + 12} L ${cx - 40} ${cy} L ${cx - 12} ${cy - 12} Z`}
                  stroke={color}
                  strokeWidth="1"
                  fill="none"
                  opacity={opacity}
                />
                <path
                  d={`M ${cx} ${cy - 20} L ${cx + 20} ${cy} L ${cx} ${cy + 20} L ${cx - 20} ${cy} Z`}
                  stroke={color}
                  strokeWidth="0.5"
                  fill="none"
                  opacity={opacity * 0.7}
                />
              </g>
            );
          })
        )}
      </svg>
    </div>
  );
}
